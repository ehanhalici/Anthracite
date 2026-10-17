#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
#include "data_text/utf8/utf8_encoding.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"
staload "search/results/search_results.sats"
staload "search/literal/literal_search.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/common/ui_common.sats"
macdef SEARCH_SNIPPET_BEFORE_BYTES = 80
macdef SEARCH_SNIPPET_AFTER_BYTES = 240
macdef SEARCH_VFS_PATH_CAPACITY_BYTES = 512
typedef ResultCursor = @{offset=int,line=int,lineStart=int}
fun row_base(row: int): int = imul(row,SEARCH_RESULT_WORDS)
fun append_jump(jumps: &Buf >> _,row: int,file: int,line: int,column: int): void = let
  val at=imul(row,SEARCH_JUMP_WORDS)
  val ()=buf_ensure(jumps,imul(iadd(at,SEARCH_JUMP_WORDS),WORD32_BYTES))
  val ()=buf_set32(jumps,iadd(at,SEARCH_JUMP_FILE),file)
  val ()=buf_set32(jumps,iadd(at,SEARCH_JUMP_LINE),line)
  val ()=buf_set32(jumps,iadd(at,SEARCH_JUMP_COLUMN),column)
in buf_set_len(jumps,imul(iadd(at,SEARCH_JUMP_WORDS),WORD32_BYTES)) end
fun append_row(source: !Buf,start: int,finish: int,match: int,length: int,
  text: &Buf >> _,metadata: &Buf >> _,row: int): void = let
  val at=row_base(row)
  val ()=buf_ensure(metadata,imul(iadd(at,SEARCH_RESULT_WORDS),WORD32_BYTES))
  val ()=buf_set32(metadata,iadd(at,SEARCH_RESULT_MATCH),match)
  val ()=buf_set32(metadata,iadd(at,SEARCH_RESULT_TEXT),buf_len(text))
  val ()=buf_set32(metadata,iadd(at,SEARCH_RESULT_LENGTH),isub(finish,start))
  val ()=buf_set32(metadata,iadd(at,SEARCH_RESULT_MATCH_LENGTH),length)
  val ()=buffer_append_range(text,source,start,finish)
in buf_set_len(metadata,imul(iadd(at,SEARCH_RESULT_WORDS),WORD32_BYTES)) end
fun cursor{n:nat} .<n>. (left: int(n),source: !Buf,state: ResultCursor): ResultCursor =
  if left = 0 then state else let val next=iadd(state.offset,1) val newline=ieq(buf_get(source,state.offset),CHAR_LF)
    val next_state: ResultCursor= @{offset=next,line=iadd(state.line,if newline then 1 else 0),
      lineStart=if newline then next else state.lineStart}
  in cursor(left-1,source,next_state) end
fun aligned{n:nat} .<n>. (left: int(n),source: !Buf,at: int,limit: int): int =
  if left = 0 then at else if ige(at,limit) then at else let val byte=buf_get(source,at)
  in if ige(byte,128) andalso ile(byte,191) then aligned(left-1,source,iadd(at,1),limit) else at end
fun snippet(source: !Buf,state: ResultCursor,finish: int,text: &Buf >> _,metadata: &Buf >> _,row: int): void = let
  val length=buf_len(source)
  val candidate=text_line_end(source,state.offset,imin(length,iadd(state.offset,SEARCH_SNIPPET_AFTER_BYTES)))
  val start=aligned(UTF8_MAX_SEQUENCE_BYTES,source,imax(state.lineStart,isub(state.offset,SEARCH_SNIPPET_BEFORE_BYTES)),state.offset)
  val stop=aligned(UTF8_MAX_SEQUENCE_BYTES,source,candidate,imin(length,iadd(candidate,UTF8_MAX_SEQUENCE_BYTES)))
in append_row(source,start,stop,isub(state.offset,start),isub(imin(finish,stop),state.offset),text,metadata,row) end
fun emit_ranges{n:nat} .<n>. (left: int(n),source: !Buf,ranges: !Buf,file: int,i: int,state: ResultCursor,
  text: &Buf >> _,metadata: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): int =
  if left = 0 then 0 else if ige(rows,SEARCH_RESULT_LIMIT) then 0 else let
    val at=buf_get32(ranges,iadd(imul(i,LITERAL_RANGE_WORDS),LITERAL_RANGE_START))
    val finish=buf_get32(ranges,iadd(imul(i,LITERAL_RANGE_WORDS),LITERAL_RANGE_FINISH))
    val next=cursor(airlock_nat(isub(at,state.offset)),source,state)
    val ()=snippet(source,next,finish,text,metadata,rows)
    val ()=append_jump(jumps,rows,file,next.line,isub(at,next.lineStart)) val ()=rows := iadd(rows,1)
  in iadd(1,emit_ranges(left-1,source,ranges,file,iadd(i,1),next,text,metadata,jumps,rows)) end
fun append_collected(source: !Buf,path: !Buf,ranges: !Buf,count: int,file: int,
  text: &Buf >> _,metadata: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchAppendResult =
  if ile(count,0) then @{matches=0,truncated=ilt(count,0)} else if ige(rows,isub(SEARCH_RESULT_LIMIT,1)) then @{matches=0,truncated=true}
  else let
    val ()=append_row(path,0,buf_len(path),SEARCH_RESULT_FILE_HEADER,0,text,metadata,rows)
    val ()=append_jump(jumps,rows,file,0,0) val ()=rows := iadd(rows,1)
    val n=emit_ranges(airlock_nat(count),source,ranges,file,0,@{offset=0,line=0,lineStart=0},text,metadata,jumps,rows)
  in @{matches=n,truncated=ilt(n,count)} end
implement search_append_matches(source,path,pattern,file,text,metadata,jumps,rows) = let
  var ranges=buf_make(0) val count=literal_collect(pattern,source,ranges,iadd(SEARCH_RESULT_LIMIT,1))
  val result=append_collected(source,path,ranges,count,file,text,metadata,jumps,rows) val ()=buf_free(ranges)
in result end
fun effective_source(path: !Buf,shadow: !Buf): Option_vt(Buf) = let
  val effective=if igt(fs_size(buf_cstr(shadow)),0) then buf_cstr(shadow) else buf_cstr(path)
  val result=(if igt(fs_size(effective),LITERAL_SOURCE_LIMIT_BYTES) then None_vt() else case+ text_file_read(effective) of
    | ~TextFileError(code) => None_vt() | ~TextFile(source) => Some_vt(source)): Option_vt(Buf)
in result end
fun disk_source(path: !Buf): Option_vt(Buf) = let var shadow=buf_make(SEARCH_VFS_PATH_CAPACITY_BYTES)
  val ()=fs_vfs_buf(buf_cstr(path),shadow,isub(SEARCH_VFS_PATH_CAPACITY_BYTES,1))
  val result=effective_source(path,shadow) val ()=buf_free(shadow)
in result end
fun read_source(path: !Buf,tabs: !Tabs): Option_vt(Buf) = let var text=buf_make(0)
  val found=tabs_copy_doc_text(tabs,path,text)
in if igt(found,0) then Some_vt(text) else let val ()=buf_free(text) in disk_source(path) end end
implement search_append_file(path,tabs,pattern,file,text,metadata,jumps,rows) =
  case+ read_source(path,tabs) of | ~None_vt() => @{matches=0,truncated=true}
  | ~Some_vt(source) => let val result=search_append_matches(source,path,pattern,file,text,metadata,jumps,rows)
    val ()=buf_free(source) in result end
