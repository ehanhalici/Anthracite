staload "mem.sats"
fun font_gl_read_pixels(b: !Buf,w: int,h: int): void
(* GPU ABI only; callers use the checked owned-buffer adapter above. *)
fun font_gl_read_raw(x: int,y: int,w: int,h: int,format: int,kind: int,p: ptr): void = "mac#glReadPixels"
