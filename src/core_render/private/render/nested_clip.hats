macdef RENDER_CLIP_WORDS = 4
macdef RENDER_CLIP_BYTES = 16
macdef RENDER_CLIP_X = 0
macdef RENDER_CLIP_Y = 1
macdef RENDER_CLIP_WIDTH = 2
macdef RENDER_CLIP_HEIGHT = 3
fun clip_end(start: int,extent: int): llint =
  g0int2int_int_llint(start)+g0int2int_int_llint(imax(0,extent))
fun clip_extent(start: int,a: llint,b: llint): int = let
  val finish=if a < b then a else b
  val extent=finish-g0int2int_int_llint(start)
in if extent <= 0LL then 0 else airlock_i32(extent) end
implement render_clip_intersection(parent,child) = let
  val x=imax(parent.x,child.x) val y=imax(parent.y,child.y)
in @{x=x,y=y,width=clip_extent(x,clip_end(parent.x,parent.width),clip_end(child.x,child.width)),
  height=clip_extent(y,clip_end(parent.y,parent.height),clip_end(child.y,child.height))} end
fun clip_read(clips: !Buf): RenderClip = let
  val at=isub(idiv(buf_len(clips),WORD32_BYTES),RENDER_CLIP_WORDS)
in @{x=buf_get32(clips,iadd(at,RENDER_CLIP_X)),y=buf_get32(clips,iadd(at,RENDER_CLIP_Y)),
  width=buf_get32(clips,iadd(at,RENDER_CLIP_WIDTH)),height=buf_get32(clips,iadd(at,RENDER_CLIP_HEIGHT))} end
fun clip_store(clips: &Buf >> _,clip: RenderClip): void = let
  val length=buf_len(clips) val at=idiv(length,WORD32_BYTES)
  val ()=buf_ensure(clips,iadd(length,RENDER_CLIP_BYTES))
  val ()=buf_set32(clips,iadd(at,RENDER_CLIP_X),clip.x)
  val ()=buf_set32(clips,iadd(at,RENDER_CLIP_Y),clip.y)
  val ()=buf_set32(clips,iadd(at,RENDER_CLIP_WIDTH),clip.width)
  val ()=buf_set32(clips,iadd(at,RENDER_CLIP_HEIGHT),clip.height)
in buf_set_len(clips,iadd(length,RENDER_CLIP_BYTES)) end
fun clip_apply(height: int,clip: RenderClip): void = let
  val ()=glEnable(GL_SCISSOR_TEST)
in glScissor(clip.x,isub(isub(height,clip.y),clip.height),clip.width,clip.height) end
implement rend_clip_push(r,x,y,width,height) = let
  val ()=rend_flush(r)
  val+ @REND(s)=r
  val parent=if igt(buf_len(s.clips),0) then clip_read(s.clips)
    else @{x=0,y=0,width=s.vw,height=s.vh}
  val clip=render_clip_intersection(parent,@{x=x,y=y,width=width,height=height})
  val ()=clip_store(s.clips,clip) val ()=clip_apply(s.vh,clip)
in fold@(r) end
extern fun clip_underflow(): void = "mac#anth_die_void"
implement rend_clip_pop(r) = let
  val ()=rend_flush(r) val+ @REND(s)=r val length=buf_len(s.clips)
  val ()=if ilt(length,RENDER_CLIP_BYTES) then clip_underflow() else ()
  val ()=buf_set_len(s.clips,isub(length,RENDER_CLIP_BYTES))
  val ()=if igt(buf_len(s.clips),0) then clip_apply(s.vh,clip_read(s.clips)) else glDisable(GL_SCISSOR_TEST)
in fold@(r) end
