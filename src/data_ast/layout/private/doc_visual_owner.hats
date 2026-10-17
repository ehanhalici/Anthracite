fun visual_release(slot: Option_vt(VisualRows)): void = case+ slot of
  | ~None_vt() => () | ~Some_vt(rows) => visual_rows_dispose(rows)
implement doc_visual_take(d) = case+ d of | @DOC(s) => let
  val rows=s.visual val ()=s.visual := None_vt() prval ()=fold@(d)
in rows end
implement doc_visual_put(d,rows) = case+ d of | @DOC(s) => let
  val old=s.visual val ()=s.visual := rows val ()=visual_release(old) prval ()=fold@(d)
in () end
fun visual_current{b:bool}(slot: !option_vt(VisualRows,b),version: int): bool = case+ slot of
  | None_vt() => false | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,k)=rows in ieq(k.version,version) end
implement doc_visual_active(d) = case+ d of | @DOC(s) => let
  val active=visual_current(s.visual,s.ver) prval ()=fold@(d)
in active end
fun visual_width{b:bool}(slot: !option_vt(VisualRows,b)): int = case+ slot of
  | None_vt() => 0 | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,key)=rows in key.width end
implement doc_visual_width(d) = case+ d of | @DOC(s) => let
  val width=visual_width(s.visual) prval ()=fold@(d)
in width end
fun visual_count{b:bool}(slot: !option_vt(VisualRows,b),version: int,line: int): int = case+ slot of
  | None_vt() => 0 | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,k)=rows
  in if ieq(k.version,version) then visual_rows_count(rows,line) else 0 end
implement doc_visual_line_rows(d,line) = case+ d of | @DOC(s) => let
  val count=visual_count(s.visual,s.ver,line) prval ()=fold@(d)
in count end
implement doc_media_take(d) = case+ d of | @DOC(s) => let
  val index=s.media val ()=s.media := buf_make(0) prval ()=fold@(d)
in index end
implement doc_media_put(d,index) = case+ d of | @DOC(s) => let
  val old=s.media val ()=s.media := index val ()=buf_free(old) prval ()=fold@(d)
in () end
