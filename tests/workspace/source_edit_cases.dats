#include "font/native/ownership/font_native_test.hats"
staload "data_ast/document/doc.sats"
staload "data_ast/editing/doc_source_edit.sats"
staload "data_font/native/ownership/font_source_grapheme.sats"
staload "data_font/text/font_text.sats"
staload "data_font/text/font_text_types.sats"
staload "data_text/grapheme/source_grapheme.sats"
staload "ui_workspace/visual/source_navigation.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "ui_workspace/tabs/ui_tab.sats"
extern fun failed(): int = "mac#anth_die_int"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),i: int,b: !Buf,s: string): void =
    if left = 0 then () else let val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,iadd(i,1),b,s) end
  val ()=copy(airlock_nat(n),0,b,s) val ()=buf_set_len(b,n)
in b end
fun score(ok: bool): int = if ok then 0 else 1
fun caret(d: !Doc,c: int,a: int): int =
  if ieq(doc_caret(d),c) andalso ieq(doc_anchor(d),a) then 0 else 1
fun edit(f: !Font,d: !Doc,e: SourceEdit,scratch: &Buf >> _): void =
  if doc_source_edit(f,d,e,scratch) then () else let val n=failed() in seen_int(n) end
fun query(f: !Font,b: !Buf,at: int,expected: SourceBoundaries): int =
  case+ font_source_grapheme_query(f,b,buf_len(b),at) of | ~None_vt() => 1 | ~Some_vt(v) =>
    if ieq(v.previous,expected.previous) andalso ieq(v.lower,expected.lower)
      andalso ieq(v.upper,expected.upper) andalso ieq(v.next,expected.next) then 0 else 1
fun cluster{fuel:nat} .<fuel>. (fuel: int(fuel),f: !Font,d: !Doc,b: !Buf,
  start: int,stop: int,i: int,scratch: &Buf >> _): int =
  if ige(i,stop) then 0 else if fuel = 0 then failed() else let
    val errors=query(f,b,i,@{previous=start,lower=start,upper=stop,next=stop})
    val ()=doc_set_caret_move(d,i) val ()=edit(f,d,SourceLeft(),scratch) val left=caret(d,start,start)
    val ()=doc_set_caret_move(d,i) val ()=edit(f,d,SourceRight(),scratch) val right=caret(d,stop,stop)
  in errors+left+right+cluster(fuel-1,f,d,b,start,stop,iadd(i,1),scratch) end
fun steps{fuel:nat} .<fuel>. (fuel: int(fuel),f: !Font,d: !Doc,b: !Buf,
  positions: List0(int),start: int,scratch: &Buf >> _): int =
  if fuel = 0 then failed() else case+ positions of | list_nil() => 0 | list_cons(stop,tail) => let
    val ()=doc_set_caret_move(d,start) val ()=edit(f,d,SourceRight(),scratch) val right=caret(d,stop,stop)
    val ()=edit(f,d,SourceLeft(),scratch) val left=caret(d,start,start)
    val ()=edit(f,d,SourceSelectRight(),scratch) val shifted=caret(d,stop,start)
    val ()=edit(f,d,SourceSelectLeft(),scratch) val reversed=caret(d,start,start)
    val inside=cluster(airlock_nat(MAX_REC_FUEL),f,d,b,start,stop,iadd(start,1),scratch)
  in right+left+shifted+reversed+inside+steps(fuel-1,f,d,b,tail,stop,scratch) end
fun sample(f: !Font,s: string,positions: List0(int)): int = let
  val b=bytes(s) val d=doc_open() var scratch=buf_make(1) val ()=doc_insert_buf(d,b,buf_len(b))
  val errors=steps(airlock_nat(MAX_REC_FUEL),f,d,b,positions,0,scratch)
  val ()=doc_set_caret_move(d,0) val ()=edit(f,d,SourceLeft(),scratch) val first=caret(d,0,0)
  val ()=doc_set_caret_move(d,buf_len(b)) val ()=edit(f,d,SourceRight(),scratch) val last=caret(d,buf_len(b),buf_len(b))
  val ()=buf_free(scratch) val ()=doc_free(d) val ()=buf_free(b)
in errors+first+last end
fun samples(f: !Font): int =
  sample(f,"İŞ",$list{int}(3,6))+sample(f,"بَّت",$list{int}(6,8))
  +sample(f,"👩🏽‍💻X",$list{int}(15,16))+sample(f,"🇹🇷🇦🇧🇨",$list{int}(8,16,20))
  +sample(f,"a\r\nb\n",$list{int}(1,3,4,5))+sample(f,"",list_nil())
fun erased(f: !Font,s: string,at: int,e: SourceEdit,start: int,stop: int): int = let
  val b=bytes(s) val d=doc_open() var scratch=buf_make(1) val ()=doc_insert_buf(d,b,buf_len(b))
  val ()=doc_set_caret_move(d,at) val ()=edit(f,d,e,scratch)
  val deleted=caret(d,start,start)+score(ieq(doc_len(d),isub(buf_len(b),isub(stop,start))))
  val ()=doc_undo(d) val undone=caret(d,at,at)+score(ieq(doc_len(d),buf_len(b)))
  val ()=doc_redo(d) val redone=caret(d,start,start)
  val ()=buf_free(scratch) val ()=doc_free(d) val ()=buf_free(b)
in deleted+undone+redone end
fun deletions(f: !Font): int =
  erased(f,"AİZ",2,SourceBackspace(),1,4)+erased(f,"AİZ",3,SourceDelete(),1,4)
  +erased(f,"AİZ",4,SourceBackspace(),1,4)+erased(f,"AİZ",1,SourceDelete(),1,4)
  +erased(f,"a\r\nb",3,SourceBackspace(),1,3)+erased(f,"a\r\nb",1,SourceDelete(),1,3)
  +erased(f,"a\r\nb",2,SourceDelete(),1,3)+erased(f,"a\r\nb",2,SourceBackspace(),1,3)
fun selection(f: !Font,a: int,c: int,e: SourceEdit): int = let
  val b=bytes("İŞZ") val d=doc_open() var scratch=buf_make(1) val ()=doc_insert_buf(d,b,7)
  val ()=doc_set_caret_move(d,a) val ()=doc_set_caret_extend(d,c) val ()=edit(f,d,e,scratch)
  val deleted=caret(d,0,0)+score(ieq(doc_len(d),1) andalso ieq(doc_byte(d,0),90))
  val ()=doc_undo(d) val undone=caret(d,c,c)+score(ieq(doc_len(d),7))
  val ()=doc_redo(d) val redone=caret(d,0,0)
  val ()=buf_free(scratch) val ()=doc_free(d) val ()=buf_free(b)
in deleted+undone+redone end
fun collapse(f: !Font): int = let
  val b=bytes("İŞZ") val d=doc_open() var scratch=buf_make(1) val ()=doc_insert_buf(d,b,7)
  val ()=doc_set_caret_move(d,1) val ()=doc_set_caret_extend(d,5) val ()=edit(f,d,SourceLeft(),scratch)
  val left=caret(d,0,0) val ()=doc_set_caret_move(d,5) val ()=doc_set_caret_extend(d,1)
  val ()=edit(f,d,SourceRight(),scratch) val right=caret(d,6,6)
  val ()=doc_set_caret_move(d,1) val ()=edit(f,d,SourceSelectRight(),scratch) val anchor=caret(d,3,1)
  val ()=edit(f,d,SourceSelectLeft(),scratch) val preserved=caret(d,0,1)
  val ()=buf_free(scratch) val ()=doc_free(d) val ()=buf_free(b)
in left+right+anchor+preserved end
fun malformed(f: !Font): int = let
  val b=buf_make(4) val ()=buf_set(b,0,226) val ()=buf_set(b,1,130)
  val ()=buf_set(b,2,65) val ()=buf_set(b,3,128) val ()=buf_set_len(b,4)
  val d=doc_open() var scratch=buf_make(1) val ()=doc_insert_buf(d,b,4)
  val errors=steps(airlock_nat(MAX_REC_FUEL),f,d,b,$list{int}(2,3,4),0,scratch)
  val ()=doc_set_caret_move(d,1) val ()=edit(f,d,SourceDelete(),scratch)
  val intact: int=if ieq(doc_len(d),2) andalso ieq(doc_byte(d,0),65) andalso ieq(doc_byte(d,1),128) then 0 else 1
  val ()=buf_free(scratch) val ()=doc_free(d) val ()=buf_free(b)
in iadd(errors,intact) end
fun relocated(f: !Font): int = let
  val b=bytes("İبَّZ") val space=bytes(" ") val d=doc_open() var scratch=buf_make(1)
  val ()=doc_insert_buf(d,b,10) val ()=doc_set_caret_move(d,2) val ()=doc_insert_buf(d,space,1)
  val ()=doc_delete_range(d,2,3)
  val errors=steps(airlock_nat(MAX_REC_FUEL),f,d,b,$list{int}(3,9,10),0,scratch)
  val ()=buf_free(scratch) val ()=doc_free(d) val ()=buf_free(space) val ()=buf_free(b)
in errors end
fun marks{n:nat} .<n>. (left: int(n),b: !Buf,i: int): void =
  if left = 0 then () else let val ()=buf_set(b,i,204) val ()=buf_set(b,iadd(i,1),135)
  in marks(left-1,b,iadd(i,2)) end
fun stress(f: !Font): int = let
  val b=buf_make(200002) val ()=buf_set(b,0,73) val ()=marks(100000,b,1)
  val ()=buf_set(b,200001,90) val ()=buf_set_len(b,200002) val before=mem_live()
  val a=query(f,b,100000,@{previous=0,lower=0,upper=200001,next=200001})
  val z=query(f,b,200001,@{previous=0,lower=200001,upper=200001,next=200002})
  val balanced=ieq(before,mem_live()) val ()=buf_free(b)
in a+z+score(balanced) end
fun inactive(): int = let
  val f=font_open() val d=doc_open() var scratch=buf_make(1) val b=bytes("İ")
  val ()=doc_insert_buf(d,b,3) val active=doc_source_edit(f,d,SourceBackspace(),scratch)
  val errors=caret(d,3,3)+score(not(active) andalso ieq(doc_len(d),3))
  val ()=font_free(f) val ()=doc_free(d) val ()=buf_free(b) val ()=buf_free(scratch)
in errors end
fun first_length(ts: !Tabs): int = case+ ts of
  | TNil() => ~1 | TCons(d,path,title,scroll,rest) => doc_len(d)
fun dispatch(f: !Font): int = let
  val b=bytes("بَّZ") val d=doc_open() var scratch=buf_make(1) val ()=doc_insert_buf(d,b,7)
  val ()=doc_set_caret_move(d,0)
  val ts=TCons(d,bytes(""),bytes(""),0,TNil())
  val (ts,cmd)=tabs_source_edit(f,ts,0,CMD_CARET_RIGHT(),scratch)
  val moved: int=if is_cmd(cmd,CMD_NONE()) andalso ieq(tabs_caret(ts,0),6) then 0 else 1
  val (ts,cmd)=tabs_source_edit(f,ts,0,CMD_SELECT_LEFT(),scratch)
  val selected: int=if is_cmd(cmd,CMD_NONE()) andalso ieq(tabs_caret(ts,0),0) then 0 else 1
  val (ts,cmd)=tabs_source_edit(f,ts,0,CMD_DELETE(),scratch)
  val deleted: int=if is_cmd(cmd,CMD_NONE()) andalso ieq(first_length(ts),1) then 0 else 1
  val (ts,cmd)=tabs_source_edit(f,ts,0,CMD_WORD_RIGHT(),scratch)
  val untouched: int=if is_cmd(cmd,CMD_WORD_RIGHT()) then 0 else 1
  val ()=tabs_free(ts) val ()=buf_free(scratch) val ()=buf_free(b)
in iadd(iadd(moved,selected),iadd(deleted,untouched)) end
extern fun native_source_edit_cases(f: !Font): int = "ext#native_source_edit_cases"
implement native_source_edit_cases(f) = let
  val before=mem_live() val errors=samples(f)+deletions(f)+selection(f,1,5,SourceDelete())
    +selection(f,5,1,SourceBackspace())+collapse(f)+malformed(f)+relocated(f)+stress(f)+inactive()+dispatch(f)
  val balanced=ieq(before,mem_live()) val result=errors+score(balanced)
  val ()=println!("event=native_source_edit errors=",result," balanced=",balanced)
in result end
extern fun native_source_edit_cpu(generated: string,source: string): int = "ext#native_source_edit_cpu"
implement native_source_edit_cpu(generated,source) = let
  val before=mem_live() val f=font_open()
  val enabled=font_text_enable(f,@{generated=generated,source=source})
  val errors: int=case+ enabled of
    | FontTextEnabled() => native_source_edit_cases(f)
    | FontTextAlreadyEnabled() => 1 | FontTextAssetsFailed(e) => 1
  val ()=font_free(f)
in iadd(errors,score(ieq(before,mem_live()))) end
