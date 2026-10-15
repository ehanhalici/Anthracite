#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_ast/doc.sats"
staload "data_ast/visual_rows.sats"
staload "data_font/font.sats"
staload "core_render/render.sats"
staload "data_font/font_text.sats"
staload "ui_workspace/visual_layout.sats"
extern fun exhausted(): int = "mac#anth_die_int"
extern fun fill_exhausted(rows: &VisualRows >> VisualRows): void = "mac#anth_die_void"
fun measure(f: !Font,r: !Rend,text: !Buf,a: int,b: int,scratch: &Buf >> _): int = let
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,a,isub(b,a))
in if ieq(a,b) then 0 else font_width_buf(f,r,scratch,isub(b,a)) end
fun boundary{n:nat} .<n>. (fuel: int(n),flags: !Buf,i: int,endpos: int): int =
  if fuel = 0 then exhausted() else if ige(i,endpos) orelse ine(buf_get(flags,i),0) then i
  else boundary(fuel-1,flags,iadd(i,1),endpos)
fun fit{n:nat} .<n>. (fuel: int(n),f: !Font,r: !Rend,text: !Buf,flags: !Buf,base: int,start: int,
  stop: int,p: int,last: int,allowed: int,width: int,scratch: &Buf >> _): int =
  if fuel = 0 then exhausted() else let val pixels=measure(f,r,text,start,p,scratch)
  in if igt(pixels,width) then if igt(allowed,start) then allowed else if igt(last,start) then last else p
    else if ige(p,stop) orelse ieq(buf_get(flags,isub(p,base)),5) then p else let
      val best=if ieq(buf_get(flags,isub(p,base)),3) then p else allowed
      val next=iadd(base,boundary(airlock_nat(MAX_REC_FUEL),flags,iadd(isub(p,base),1),isub(stop,base)))
    in fit(fuel-1,f,r,text,flags,base,start,stop,next,p,best,width,scratch) end end
fun append(f: !Font,r: !Rend,rows: &VisualRows >> VisualRows,a: int,b: int,line: int,ordinal: int,scratch: &Buf >> _): void = let
  val+ VisualRows(text,map,lines,data,n,key)=rows
  val width=measure(f,r,text,a,b,scratch)
in visual_rows_append(rows,@{start=a,finish=b,width=width,line=line,ordinal=ordinal}) end
fun is_specialized_block(k: NodeKind): bool =
  is_kind(k, KQuote) orelse is_kind(k, KCallout) orelse is_kind(k, KCode)
  orelse is_kind(k, KTable) orelse is_kind(k, KTableRow) orelse is_kind(k, KTableCell)

fun block_kind_at{n:nat} .<n>. (fuel: int(n), d: !Doc, pos: int, i: int, best_k: NodeKind): NodeKind =
  if fuel = 0 then best_k
  else if ige(i, doc_nnodes(d)) then best_k
  else let
    val st = doc_node_start(d, i)
    val en = doc_node_end(d, i)
    val covers = ige(pos, st) andalso ilt(pos, en)
    val k = doc_node_kind(d, i)
    val new_k = if covers andalso is_specialized_block(k) then k else best_k
  in
    block_kind_at(fuel - 1, d, pos, iadd(i, 1), new_k)
  end

fun line_target_width(d: !Doc, line: int, default_w: int): int = let
  val st = doc_line_start(d, line)
  val k = block_kind_at(airlock_nat(MAX_REC_FUEL), d, st, 0, KNone)
in
  if is_kind(k, KQuote) orelse is_kind(k, KCallout) then imax(32, isub(default_w, 24))
  else if is_kind(k, KCode) then imax(32, isub(default_w, 16))
  else default_w
end

fun append_known(rows: &VisualRows >> VisualRows,a: int,b: int,line: int,ordinal: int,width: int): void =
  visual_rows_append(rows,@{start=a,finish=b,width=width,line=line,ordinal=ordinal})

fun line_rows{n:nat} .<n>. (fuel: int(n),f: !Font,r: !Rend,rows: &VisualRows >> VisualRows,flags: !Buf,
  base: int,a: int,b: int,line: int,ordinal: int,target_w: int,scratch: &Buf >> _): void =
  if fuel = 0 then fill_exhausted(rows) else if ige(a,b) then () else let
    val+ VisualRows(text,map,lines,data,count,key)=rows
    val full_w=measure(f,r,text,a,b,scratch)
  in
    if ile(full_w,target_w) then
      append_known(rows,a,b,line,ordinal,full_w)
    else let
      val next=iadd(base,boundary(airlock_nat(MAX_REC_FUEL),flags,iadd(isub(a,base),1),isub(b,base)))
      val endpos=fit(airlock_nat(MAX_REC_FUEL),f,r,text,flags,base,a,b,next,a,a,target_w,scratch)
      val ()=append(f,r,rows,a,endpos,line,ordinal,scratch)
    in line_rows(fuel-1,f,r,rows,flags,base,endpos,b,line,iadd(ordinal,1),target_w,scratch) end
  end

fun one(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,line: int,scratch: &Buf >> _): void = let
  val st=doc_line_start(d,line)
  val raw=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
  val en=if igt(raw,st) andalso ieq(doc_byte(d,isub(raw,1)),10) then isub(raw,1) else raw
  val a=visual_rows_offset(rows,st) val b=visual_rows_offset(rows,en)
  val+ VisualRows(text,map,lines,data,count,key)=rows val ()=buf_set32(lines,line,count)
  val target_w=line_target_width(d,line,key.width)
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,a,isub(b,a))
  val flags=font_text_boundaries(f,scratch,isub(b,a))
  val ()=if ieq(a,b) then append_known(rows,a,b,line,0,0)
    else line_rows(airlock_nat(MAX_REC_FUEL),f,r,rows,flags,a,a,b,line,0,target_w,scratch)
in buf_free(flags) end
fun lines{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,i: int,scratch: &Buf >> _): void =
  if left = 0 then let val+ VisualRows(t,m,l,data,count,key)=rows in buf_set32(l,i,count) end
  else let val ()=one(f,r,d,rows,i,scratch) in lines(left-1,f,r,d,rows,iadd(i,1),scratch) end
implement visual_wrap_fill(f,r,d,rows) = let var scratch=buf_make(256)
  val ()=lines(airlock_nat(doc_nlines(d)),f,r,d,rows,0,scratch)
in buf_free(scratch) end
