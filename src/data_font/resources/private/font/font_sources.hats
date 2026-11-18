(* Face source bookkeeping: every successful primary/fallback load records its
   path and takes a new process-wide source id (worker fonts reload on change). *)
extern fun font_source_next(): int = "mac#anth_font_source_next"
fun append_text{n:nat} .<n>. (left: int(n),b: &Buf >> _,text: string,i: int): void =
  if left = 0 then () else let val () = buf_push(b,c_str_byte(text,i)) in append_text(left-1,b,text,iadd(i,1)) end
fun replace_text(b: &Buf >> _,text: string): void = let
  val () = buf_set_len(b,0)
in append_text(airlock_nat(c_strlen(text)),b,text,0) end
implement font_note_primary_path(f,path) = case+ f of | @FONT(s) => let
  val () = replace_text(s.primary_path,path)
  val () = s.source_id := font_source_next()
in fold@(f) end
implement font_note_fallback_path(f,path) = case+ f of | @FONT(s) => let
  val () = replace_text(s.fallback_path,path)
  val () = s.source_id := font_source_next()
in fold@(f) end
implement font_source_id(f) = case+ f of | @FONT(s) => let val id = s.source_id in fold@(f); id end
implement font_source_paths(f,primary,fallback) = case+ f of | @FONT(s) => let
  val primary_bytes = buf_len(s.primary_path) val fallback_bytes = buf_len(s.fallback_path)
  val () = buf_append_at(primary,s.primary_path,0,primary_bytes)
  val () = buf_append_at(fallback,s.fallback_path,0,fallback_bytes)
in fold@(f) end
