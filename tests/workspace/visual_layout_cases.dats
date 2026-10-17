#include "font/native/ownership/font_native_test.hats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/layout_internal.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "data_font/resources/font_hit.sats"
staload "data_font/text/font_text.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/resources/private/font_storage.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
staload "ui_workspace/visual/visual_paint.sats"
staload "ui_workspace/visual/visual_query.sats"
staload "ui_workspace/visual/visual_plan.sats"
staload "ui_workspace/visual/visual_navigation.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "ui_workspace/render/ui_render.sats"
staload "ui_workspace/embed/embedded_doc.sats"
staload "font/resources/font_gl_airlock.sats"
staload "core_render/gl.sats"
staload "core_runtime/performance.sats"
staload "os/selftest_fixture.sats"
extern fun native_visual_layout_cases(f: !Font,r: !Rend): int = "ext#native_visual_layout_cases"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void =
    if left = 0 then () else let val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun rows{n:nat} .<n>. (left: int(n),snapshot: !VisualRows,i: int): int =
  if left = 0 then 0 else let val row=visual_rows_at(snapshot,i)
    val+ VisualRows(text,map,lines,data,count,key,plans)=snapshot
    val starts=ilt(row.start,row.finish) orelse ieq(row.width,0)
    val bounded=ile(row.width,key.width)
  in iadd(if starts andalso bounded then 0 else 1,rows(left-1,snapshot,iadd(i,1))) end
fun snapshot(d: !Doc): int = let val state=doc_visual_take(d)
  val errors=case+ state of | None_vt() => 1 | Some_vt(s) => let val+ VisualRows(t,m,l,data,n,k,plans)=s
  in rows(airlock_nat(n),s,0) end
  val ()=doc_visual_put(d,state)
in errors end
fun pixel{n:nat} .<n>. (left: int(n),image: !Buf,i: int,height: int,found: &int >> _): int =
  if left = 0 then 0 else let val at=imul(i,4)
    val blue=ieq(buf_get(image,at),58) andalso ieq(buf_get(image,iadd(at,1)),74) andalso ieq(buf_get(image,iadd(at,2)),92)
    val x=imod(i,128) val y=isub(127,idiv(i,128))
    val ()=if blue then found := iadd(found,1) else ()
    val error=if blue andalso (ige(x,90) orelse ige(y,height)) then 1 else 0
  in iadd(error,pixel(left-1,image,iadd(i,1),height,found)) end
fun selection(f: !Font,r: !Rend,d: !Doc,lh: int,endpos: int): int = let
  val ()=doc_set_caret_move(d,0) val ()=doc_set_caret_extend(d,endpos)
  val ()=rend_begin(r,640,480) var scratch=buf_make(256)
  val ()=visual_draw_selection(f,r,d,20,20,0,lh,scratch) val ()=rend_flush(r)
  val image=buf_make(WORD16_MODULUS) val ()=font_gl_read_pixels(image,128,128) var found: int=0
  val errors=pixel(airlock_nat(16384),image,0,doc_line_step(d,0),found)
  val ()=buf_free(image) val ()=buf_free(scratch)
in iadd(errors,if igt(found,0) then 0 else 1) end
fun caret(f: !Font,d: !Doc,lh: int): int = let var scratch=buf_make(256)
  val ()=doc_set_caret_move(d,0)
  val click=visual_click_source(f,d,20,20,20,20,0,lh,scratch)
  val point=visual_caret_point(f,d,20,20,0,lh,scratch)
  val ()=buf_free(scratch)
in if ieq(click,0) andalso ieq(point.x,20) andalso ieq(point.y,20) then 0 else 1 end
fun font_scope(f: !Font,r: !Rend,d: !Doc,lh: int,endpos: int): int = let var scratch=buf_make(256)
  val old=font_get_px(f) val ()=doc_set_caret_move(d,2)
  val expected=visual_caret_point(f,d,20,20,0,lh,scratch)
  val ()=font_set_px(f,48) val actual=visual_caret_point(f,d,20,20,0,font_line_h(f),scratch)
  val restored=ieq(font_get_px(f),48) andalso ieq(expected.x,actual.x) andalso ieq(expected.y,actual.y)
  val pixels=selection(f,r,d,font_line_h(f),endpos)
  val ()=font_set_px(f,old) val ()=buf_free(scratch)
in iadd(pixels,if restored then 0 else 1) end
fun equal{n:nat} .<n>. (left: int(n),b: !Buf,s: string,i: int): bool =
  if left = 0 then true else ieq(buf_get(b,i),c_str_byte(s,i)) andalso equal(left-1,b,s,iadd(i,1))
fun projected{b:bool}(state: !option_vt(VisualRows,b)): int = case+ state of
  | None_vt() => 1 | Some_vt(rows) => let val+ VisualRows(text,map,lines,data,n,key,plans)=rows
    val expected="İŞ Başlık\n" val length=c_strlen(expected)
  in if ieq(buf_len(text),length) andalso equal(airlock_nat(length),text,expected,0) then 0 else 1 end
fun markdown(f: !Font,r: !Rend): int = let val d=doc_open() val b=bytes("**İŞ** [[note|Başlık]]\n")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b)
  val ()=visual_layout_prepare(f,r,d,90,ViewRead) val state=doc_visual_take(d)
  val errors=projected(state) val ()=doc_visual_put(d,state) val ()=doc_free(d)
in errors end
fun hard_lines(f: !Font,r: !Rend): int = let val d=doc_open() val b=bytes("A\342\200\251B\013C\r\nD")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b)
  val ()=visual_layout_prepare(f,r,d,600,ViewEdit)
  val lh=font_document_line_height(f,font_line_h(f)) val h=doc_layout_mode(d,lh,0,680)
  val expected=ieq(doc_visual_line_rows(d,0),3) andalso ieq(doc_line_step(d,0),imul(3,lh))
  val ()=doc_free(d)
in if expected then 0 else 1 end
fun navigation(f: !Font,r: !Rend): int = let val d=doc_open() val b=bytes("İŞİİ İŞİİ İŞİİ İŞİİ\n")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b) val ()=doc_set_caret_move(d,0)
  val ()=visual_layout_prepare(f,r,d,90,ViewEdit) var scratch=buf_make(256)
  val height=doc_layout_mode(d,font_document_line_height(f,font_line_h(f)),0,170)
  val ts=TCons(d,buf_make(1),buf_make(1),0,TNil())
  val (down,left)=tabs_visual_vertical(f,r,ts,0,CMD_SELECT_DOWN(),scratch)
  val moved=igt(tabs_caret(down,0),0) andalso is_cmd(left,CMD_NONE())
  val (up,left2)=tabs_visual_vertical(f,r,down,0,CMD_CARET_UP(),scratch)
  val returned=ieq(tabs_caret(up,0),0) andalso is_cmd(left2,CMD_NONE())
  val ()=tabs_free(up) val ()=buf_free(scratch)
in if moved andalso returned then 0 else 1 end
fun test(f: !Font,r: !Rend,d: !Doc): int = let
  val b=bytes("İŞİİ İŞİİ İŞİİ İŞİİ\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n")
  val ()=doc_insert_buf(d,b,buf_len(b)) val ()=buf_free(b)
  val lh=font_document_line_height(f,font_line_h(f))
  val ()=visual_layout_prepare(f,r,d,90,ViewEdit) val h=doc_layout_mode(d,lh,0,170)
  val count=doc_visual_line_rows(d,0)
  val geometry=igt(count,1) andalso ieq(doc_line_step(d,0),imul(count,lh))
    andalso ige(doc_line_y(d,2),doc_line_step(d,0)) andalso igt(h,doc_line_y(d,2))
  val errors=iadd(snapshot(d),iadd(font_scope(f,r,d,lh,isub(doc_line_start(d,1),1)),caret(f,d,lh)))
  val ()=visual_layout_prepare(f,r,d,260,ViewEdit) val resized=doc_layout_mode(d,lh,0,340)
  val fewer=ilt(doc_visual_line_rows(d,0),count)
in iadd(errors,if geometry andalso fewer then 0 else 1) end
fun folding_and_task(f: !Font, r: !Rend): int = let
  val d = doc_open()
  val b = bytes("# Baslik 1\nParagraf 1\n\nParagraf 2\n# Baslik 2\n- [ ] Gorev 1\n")
  val () = doc_insert_buf(d, b, buf_len(b))
  val () = buf_free(b)
  val lh = font_document_line_height(f, font_line_h(f))
  val () = visual_layout_prepare(f, r, d, 200, ViewEdit)
  val h_orig = doc_layout_mode(d, lh, 0, 280)
  val n0 = node_covering(d, 5, 0, 0, 0, ~1)
  val ok_h0 = is_heading(doc_node_kind(d, n0))
  val () = doc_toggle(d, n0)
  val () = visual_layout_prepare(f, r, d, 200, ViewEdit)
  val h_folded = doc_layout_mode(d, lh, 0, 280)
  val ok_fold = ilt(h_folded, h_orig) andalso ieq(doc_line_step(d, 1), 0) andalso ieq(doc_line_step(d, 2), 0) andalso ieq(doc_line_step(d, 3), 0)
  val () = doc_toggle(d, n0)
  val () = visual_layout_prepare(f, r, d, 200, ViewEdit)
  val h_restored = doc_layout_mode(d, lh, 0, 280)
  val ok_unfold = ieq(h_restored, h_orig) andalso igt(doc_line_step(d, 1), 0)
  val task_y = iadd(doc_line_y(d, 5), idiv(lh, 2))
  val n_task = node_covering(d, task_y, 0, 0, 0, ~1)
  val ok_task_node = is_kind(doc_node_kind(d, n_task), KTask)
  val () = doc_toggle_task(d, n_task)
  val mark_pos = iadd(doc_line_start(d, 5), 3)
  val ok_task_toggle = ieq(doc_byte(d, mark_pos), 120)
  val () = doc_free(d)
  val ok = ok_h0 andalso ok_fold andalso ok_unfold andalso ok_task_node andalso ok_task_toggle
  val ()=println!("event=visual_fold heading=",ok_h0," folded=",ok_fold," unfolded=",ok_unfold,
    " task_node=",ok_task_node," task_toggle=",ok_task_toggle)
in
  if ok then 0 else 1
end
fun repeat_words{n:nat} .<n>. (left: int(n),b: &Buf >> _): void =
  if left = 0 then () else let val ()=buffer_append_string(b,"office İŞ بسم الله 123 ")
  in repeat_words(left-1,b) end
fun wrap_scale(f: !Font,r: !Rend,words: int): int = let
  val d=doc_open() var source=buf_make(256)
  val ()=repeat_words(airlock_nat(words),source) val length=buf_len(source)
  val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val ()=performance_enable(1) val ()=performance_reset()
  val ()=visual_layout_prepare(f,r,d,240,ViewEdit)
  val count=doc_visual_line_rows(d,0)
  val calls=performance_value(PERF_SHAPE_CALLS)
  val limit=g0int2uint_int_ullint(iadd(imul(count,2),2))
  val errors=iadd(snapshot(d),if calls <= limit then 0 else 1)
  val ()=println!("event=wrap_scale words=",words," rows=",count," shapes=",calls," limit=",limit)
  val ()=performance_enable(0) val ()=doc_free(d)
in errors end
fun clip_pixels{n:nat} .<n>. (left: int(n),pixels: !Buf,i: int): int =
  if left = 0 then 0 else let
    val x=imod(i,128) val y=isub(127,idiv(i,128)) val at=imul(i,4)
    val white=ieq(buf_get(pixels,at),255) andalso ieq(buf_get(pixels,iadd(at,1)),255)
      andalso ieq(buf_get(pixels,iadd(at,2)),255)
    val inside=ige(x,16) andalso ilt(x,80) andalso ige(y,32) andalso ilt(y,96)
    val error=if white = inside then 0 else 1
  in iadd(error,clip_pixels(left-1,pixels,iadd(i,1))) end
fun nested_clips(r: !Rend): int = let
  val ()=rend_begin(r,128,128)
  val ()=rend_clip_push(r,16,32,64,64) val ()=rend_clip_push(r,0,0,128,128)
  val ()=rend_rect(r,0,0,128,128,0xFFFFFFFFu) val ()=rend_clip_pop(r)
  val ()=rend_clip_push(r,0,0,8,8)
  val ()=rend_rect(r,0,0,128,128,0xFF0000FFu) val ()=rend_clip_pop(r)
  val ()=rend_clip_pop(r) val ()=rend_rect(r,0,0,8,8,0x00FF00FFu)
  val ()=rend_flush(r) val pixels=buf_make(imul(imul(128,128),4))
  val ()=font_gl_read_raw(0,0,128,128,GL_RGBA,GL_UNSIGNED_BYTE,buf_ptr(pixels))
  val errors=clip_pixels(16384,pixels,0)
  val restored=ieq(buf_get(pixels,imul(imul(127,128),4)),0)
    andalso ieq(buf_get(pixels,iadd(imul(imul(127,128),4),1)),255)
  val ()=buf_free(pixels)
in iadd(errors,if restored then 0 else 1) end
fun warm_layout(f: !Font,r: !Rend): int = let
  val d=doc_open() val source=bytes("plain text\n") val length=buf_len(source)
  val ()=doc_insert_buf(d,source,length) var cache=CNil() val vault=buf_make(0)
  val first=prepare_document_layout(f,d,cache,r,vault,24,240,ViewRead)
  val ()=performance_enable(1) val ()=performance_reset()
  val second=prepare_document_layout(f,d,cache,r,vault,24,240,ViewRead)
  val hit=ieq(first,second) andalso performance_value(PERF_MEDIA_INDEX_BUILDS)=0ULL
    andalso performance_value(PERF_VISUAL_INDEX_BUILDS)=0ULL
    andalso performance_value(PERF_LAYOUT_BUILDS)=0ULL andalso performance_value(PERF_WRAP_BUILDS)=0ULL
  val ()=doc_insert_buf(d,source,length) val ()=performance_reset()
  val changed=prepare_document_layout(f,d,cache,r,vault,24,240,ViewRead)
  val invalidated=performance_value(PERF_MEDIA_INDEX_BUILDS)=1ULL
    andalso performance_value(PERF_VISUAL_INDEX_BUILDS)=1ULL
  val ()=performance_enable(0) val ()=buf_free(source) val ()=buf_free(vault)
  val ()=cache_free(cache) val ()=doc_free(d)
in if hit andalso invalidated then 0 else 1 end
fun evict_font_cache{n:nat} .<n>. (left: int(n),f: !Font,i: int): void =
  if left = 0 then () else let var source=buf_make(32)
    val ()=buffer_append_string(source,"eviction ")
    val ()=buf_push(source,iadd(CHAR_UPPER_A,idiv(i,16))) val ()=buf_push(source,iadd(CHAR_UPPER_A,imod(i,16)))
    val length=buf_len(source) val width=font_text_width(f,source,length) val ()=buf_free(source)
  in evict_font_cache(left-1,f,iadd(i,1)) end
fun owned_row_plans(f: !Font,r: !Rend): int = let
  val d=doc_open() val source=bytes("Türkçe **metin** بسم الله الرحمن الرحيم\nikinci satır\n")
  val length=buf_len(source) val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val ()=doc_set_caret_move(d,0)
  val ()=visual_layout_prepare(f,r,d,240,ViewRead) val height=doc_layout_mode(d,24,1,320)
  var scratch: Buf=buf_make(256) val ()=rend_begin(r,640,480)
  val first=visual_draw_slice(f,r,d,0,doc_len(d),20,20,0,24,440,0xFFFFFFFFu,scratch)
  val ()=evict_font_cache(256,f,0) val ()=performance_enable(1) val ()=performance_reset()
  val second=visual_draw_slice(f,r,d,0,doc_len(d),20,20,0,24,440,0xFFFFFFFFu,scratch)
  val at=visual_click_source(f,d,20,20,20,20,0,24,scratch)
  val point=visual_caret_point(f,d,20,20,0,24,scratch)
  val shared=performance_value(PERF_SHAPE_CALLS)=0ULL andalso ieq(first,second)
  val calls=performance_value(PERF_SHAPE_CALLS)
  val ()=println!("event=owned_row_plans first=",first," second=",second," shapes=",calls)
  val ()=performance_enable(0) val ()=buf_free(scratch) val ()=doc_free(d)
in if shared then 0 else 1 end
fun rtl_row_plans{n:nat} .<n>. (left: int(n),f: !Font,rows: !VisualRows,index: int,scratch: &Buf >> _): int =
  if left = 0 then 0 else let val row=visual_rows_at(rows,index)
    val+ VisualRows(t,m,l,data,count,key,plans)=rows
    val hit=visual_plan_query(f,rows,index,20,QueryCaret(0),scratch)
    val layout=visual_plans_take(plans,index)
    val errors=case+ layout of | ~None_vt() => 1 | ~Some_vt(layout) => let
        val correct=ieq(row.line,1) orelse (ieq(font_span_direction(layout),1) andalso ieq(hit.base,iadd(20,isub(key.width,row.width))))
        val ()=visual_plans_put(plans,index,layout)
      in if correct then 0 else 1 end
  in iadd(errors,rtl_row_plans(left-1,f,rows,iadd(index,1),scratch)) end
fun paragraph_bidi_rows(f: !Font,r: !Rend): int = let
  val d=doc_open() val source=bytes("ببب 123 456 789 123\n") val length=buf_len(source)
  val ()=doc_insert_buf(d,source,length) val ()=buf_free(source) var scratch: Buf=buf_make(256)
  val ()=visual_layout_prepare(f,r,d,40,ViewRead) val state=doc_visual_take(d)
  val errors=case+ state of | None_vt() => 1 | Some_vt(rows) => let
    val+ VisualRows(t,m,l,data,count,key,plans)=rows
  in iadd(if count > 2 then 0 else 1,rtl_row_plans(airlock_nat(count),f,rows,0,scratch)) end
  val ()=doc_visual_put(d,state) val ()=doc_free(d) val ()=buf_free(scratch)
in errors end
fun embed_fixture_fill{n:nat} .<n>. (left: int(n),child: &Buf >> _,parent: &Buf >> _,i: int): void =
  if left = 0 then () else let
    val ()=repeat_words(airlock_nat(imul(iadd(i,1),4)),child)
    val ()=buffer_append_string(child," ^") val ()=buf_push(child,iadd(CHAR_LOWER_A,i))
    val ()=buffer_append_string(child,"\n\n")
    val ()=buffer_append_string(parent,"![[child#^") val ()=buf_push(parent,iadd(CHAR_LOWER_A,i))
    val ()=buffer_append_string(parent,"]]\n")
  in embed_fixture_fill(left-1,child,parent,iadd(i,1)) end
fun embed_heights{n:nat} .<n>. (left: int(n),d: !Doc,i: int,small: &int >> _,large: &int >> _): int =
  if left = 0 then 0 else let val embedded=is_kind(doc_node_kind(d,i),KEmbed)
    val height=doc_node_height(d,i)
    val ()=if embedded then (small := imin(small,height); large := imax(large,height)) else ()
  in iadd(if embedded then 1 else 0,embed_heights(left-1,d,iadd(i,1),small,large)) end
fun embed_file_cache{n:nat} .<n>. (fuel: int(n),cache: !Cache): int =
  if fuel = 0 then 0 else case+ cache of | CNil() => 0
  | CCons(p,t,w,h,rest) => embed_file_cache(fuel-1,rest)
  | CSelection(info,path,rest) => embed_file_cache(fuel-1,rest)
  | CWork(state,pins,rest) => embed_file_cache(fuel-1,rest)
  | CView(path,stamp,state,rest) => embed_file_cache(fuel-1,rest)
  | CEmbed(p,mtime,d,w,h,rest) => iadd(1,embed_file_cache(fuel-1,rest))
fun cached_first_byte{n:nat} .<n>. (fuel: int(n),cache: !Cache): int =
  if fuel = 0 then ~1 else case+ cache of | CNil() => ~1
  | CCons(p,t,w,h,rest) => cached_first_byte(fuel-1,rest)
  | CSelection(info,path,rest) => cached_first_byte(fuel-1,rest)
  | CWork(state,pins,rest) => cached_first_byte(fuel-1,rest)
  | CView(path,stamp,state,rest) => cached_first_byte(fuel-1,rest)
  | CEmbed(p,mtime,d,w,h,rest) => doc_byte(d,0)
fun embed_reload(f: !Font,r: !Rend,d: !Doc,cache: &Cache >> _,root: !Buf,expected: int): int = let
  val ()=performance_reset()
  val height=prepare_document_layout(f,d,cache,r,root,24,300,ViewRead)
  val first=cached_first_byte(128,cache)
in if performance_value(PERF_DOCUMENT_LOADS)=1ULL andalso ieq(first,expected) then 0 else 1 end
fun embed_refresh(f: !Font,r: !Rend,d: !Doc,cache: &Cache >> _,root: !Buf,path: !Buf,source: !Buf): int = let
  val length=buf_len(source) val ()=buf_set(source,0,CHAR_UPPER_A)
  val wrote=fs_write_buf(buf_cstr(path),source,length)
  val physical=embed_reload(f,r,d,cache,root,CHAR_UPPER_A)
  val shadow=buf_make(512) val ()=fs_vfs_buf(buf_cstr(path),shadow,511)
  val ()=buf_set(source,0,CHAR_UPPER_A+1)
  val wrote_shadow=fs_write_buf(buf_cstr(shadow),source,length)
  val redirected=embed_reload(f,r,d,cache,root,CHAR_UPPER_A+1)
  val removed=fs_unlink(buf_cstr(shadow))
  val restored=embed_reload(f,r,d,cache,root,CHAR_UPPER_A)
  val ()=buf_free(shadow)
in iadd(physical+redirected+restored,if ieq(wrote,1) andalso ieq(wrote_shadow,1) andalso ieq(removed,0) then 0 else 1) end
fun populate_views{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,cache: &Cache >> _,root: !Buf,i: int): void =
  if left = 0 then () else let
    val height=prepare_document_layout(f,d,cache,r,root,24,iadd(340,imul(i,7)),ViewRead)
  in populate_views(left-1,f,r,d,cache,root,iadd(i,1)) end
fun embed_widths(f: !Font,r: !Rend,d: !Doc,cache: &Cache >> _,root: !Buf): int = let
  val narrow=prepare_document_layout(f,d,cache,r,root,24,240,ViewRead)
  val wide=prepare_document_layout(f,d,cache,r,root,24,480,ViewRead)
  val ()=performance_reset() val restored=prepare_document_layout(f,d,cache,r,root,24,300,ViewRead)
  val reused=performance_value(PERF_DOCUMENT_LOADS)=0ULL andalso performance_value(PERF_WRAP_BUILDS)=1ULL
  val ()=populate_views(20,f,r,d,cache,root,0)
  val stats=cache_embed_stats(cache)
  val bounded=ieq(stats.documents,1) andalso ieq(stats.views,128) andalso ieq(stats.pending,0) andalso stats.viewBytes <= 67108864LL
  val ()=println!("event=embed_views width_reused=",reused," bounded=",bounded)
in if reused andalso bounded andalso igt(narrow,wide) then 0 else 1 end
fun embed_fixture_test(f: !Font,r: !Rend,root: !Buf,path: !Buf): int = let
  var child=buf_make(256) var parent=buf_make(256)
  val ()=embed_fixture_fill(7,child,parent,0) val child_length=buf_len(child)
  val written=fs_write_buf(buf_cstr(path),child,child_length)
  val d=doc_open() val length=buf_len(parent) val ()=doc_insert_buf(d,parent,length)
  var cache: Cache=CNil() val ()=performance_enable(1) val ()=performance_reset()
  val total=prepare_document_layout(f,d,cache,r,root,24,300,ViewRead)
  val loaded=performance_value(PERF_DOCUMENT_LOADS)=1ULL andalso performance_value(PERF_AST_PARSES)=1ULL
  var small: int=SIGNED_INT_MAX_VALUE var large: int=0
  val count=embed_heights(airlock_nat(doc_nnodes(d)),d,0,small,large)
  val files=embed_file_cache(128,cache)
  val ranged=ieq(count,7) andalso igt(large,small) andalso ieq(files,1)
  val ()=performance_reset() val warm=prepare_document_layout(f,d,cache,r,root,24,300,ViewRead)
  val reused=performance_value(PERF_DOCUMENT_LOADS)=0ULL andalso ieq(total,warm)
  val no_layout=performance_value(PERF_WRAP_BUILDS)=0ULL andalso performance_value(PERF_LAYOUT_BUILDS)=0ULL
  val widths=embed_widths(f,r,d,cache,root)
  val refresh=embed_refresh(f,r,d,cache,root,path,child)
  val ()=performance_enable(0) val ()=cache_free(cache) val ()=doc_free(d)
  val ()=buf_free(child) val ()=buf_free(parent)
  val ()=println!("event=embed_cache loaded=",loaded," ranged=",ranged," reused=",reused)
in iadd(widths,iadd(refresh,if ieq(written,1) andalso loaded andalso ranged andalso reused andalso no_layout then 0 else 1)) end
fun selection_parent_draw(f: !Font,r: !Rend,tabs: !Tabs,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): void =
  case+ tabs of | TNil() => () | TCons(d,path,title,scroll,rest) => let
    val ()=rend_begin(r,640,480)
    val ()=draw_doc(f,r,d,0,36,640,444,0,font_line_h(f),root,cache,scratch,ViewRead)
  in rend_flush(r) end
fun embed_top{n:nat} .<n>. (left: int(n),d: !Doc,wanted: int,i: int): int =
  if left = 0 then ~1 else let val embedded=is_kind(doc_node_kind(d,i),KEmbed)
  in if embedded andalso ieq(wanted,0) then iadd(36,doc_node_y(d,i))
    else embed_top(left-1,d,if embedded then isub(wanted,1) else wanted,iadd(i,1)) end
fun selection_top(tabs: !Tabs,wanted: int): int = case+ tabs of
  | TNil() => ~1 | TCons(d,p,t,s,rest) => embed_top(airlock_nat(doc_nnodes(d)),d,wanted,0)
fun first_embed{n:nat} .<n>. (left: int(n),d: !Doc,i: int): int =
  if left = 0 then ~1 else if is_kind(doc_node_kind(d,i),KEmbed) then i else first_embed(left-1,d,iadd(i,1))
fun selection_x(f: !Font,r: !Rend,tabs: !Tabs): int = case+ tabs of
  | TNil() => 0 | TCons(d,p,t,s,rest) => let val node=first_embed(airlock_nat(doc_nnodes(d)),d,0)
    val indent=imul(doc_node_depth(d,node),20) val x=iadd(editor_colx(f,r,0,640),indent)
  in editor_colx(f,r,x,isub(doc_visual_width(d),indent)) end
fun selection_pixels{n:nat} .<n>. (left: int(n),pixels: !Buf,i: int,bottom: int,found: &int >> _): int =
  if left = 0 then 0 else let val at=imul(i,4)
    val selected=ieq(buf_get(pixels,at),58) andalso ieq(buf_get(pixels,iadd(at,1)),74) andalso ieq(buf_get(pixels,iadd(at,2)),92)
    val y=isub(479,idiv(i,640)) val ()=if selected then found := iadd(found,1) else ()
    val error=if selected andalso ige(y,bottom) then 1 else 0
  in iadd(error,selection_pixels(left-1,pixels,iadd(i,1),bottom,found)) end
fun selection_ink(f: !Font,r: !Rend,tabs: !Tabs,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): int = let
  val ()=selection_parent_draw(f,r,tabs,root,cache,scratch)
  val pixels=buf_make(imul(imul(640,480),4))
  val ()=font_gl_read_raw(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,buf_ptr(pixels))
  val bottom=selection_top(tabs,1) var found: int=0
  val errors=selection_pixels(307200,pixels,0,isub(bottom,4),found)
  val ()=buf_free(pixels)
in iadd(errors,if igt(found,0) then 0 else 1) end
fun selected_info{n:nat} .<n>. (left: int(n),cache: !Cache): Option(EmbeddedSelection) =
  if left = 0 then None() else case+ cache of | CNil() => None() | CSelection(info,path,rest) => Some(info)
  | CWork(state,pins,rest) => selected_info(left-1,rest)
  | CCons(p,t,w,h,rest) => selected_info(left-1,rest) | CEmbed(p,s,d,w,h,rest) => selected_info(left-1,rest)
  | CView(p,s,state,rest) => selected_info(left-1,rest)
fun selected_view_exists{n:nat} .<n>. (left: int(n),cache: !Cache,info: EmbeddedSelection): bool =
  if left = 0 then false else case+ cache of | CNil() => false
  | CWork(state,pins,rest) => selected_view_exists(left-1,rest,info)
  | CSelection(s,p,rest) => selected_view_exists(left-1,rest,info)
  | CCons(p,t,w,h,rest) => selected_view_exists(left-1,rest,info)
  | CEmbed(p,s,d,w,h,rest) => selected_view_exists(left-1,rest,info)
  | CView(p,s,state,rest) => let val matches=case+ state of | EmbedViewPending() => false
      | EmbedViewReady(key,g) => visual_key_context_matches(key,info.view) andalso embedded_source_equal(s,info.source)
    in matches orelse selected_view_exists(left-1,rest,info) end
fun selected_view_pin(f: !Font,r: !Rend,tabs: !Tabs,root: !Buf,cache: &Cache >> _): int = let
  val ()=case+ tabs of | TNil() => () | TCons(d,p,t,s,rest) => populate_views(140,f,r,d,cache,root,0)
  val info=selected_info(512,cache)
  val found=case+ info of | None() => false | Some(selection) => selected_view_exists(512,cache,selection)
  val stats=cache_embed_stats(cache)
in if found andalso ieq(stats.views,128) andalso stats.viewBytes <= 67108864LL then 0 else 1 end
fun selection_drag(f: !Font,r: !Rend,tabs: !Tabs,root: !Buf,cache: &Cache >> _,scratch: &Buf >> _): int = let
  val top=selection_top(tabs,0) val x=selection_x(f,r,tabs)
  val word=bytes("alpha") val width=font_width_buf(f,r,word,5) val ()=buf_free(word)
  val began=tabs_embed_select(f,r,tabs,0,x,iadd(top,1),0,640,font_line_h(f),root,cache,scratch,false)
  val candidate=not(cache_embed_selection_dragged(cache))
  val extended=tabs_embed_select(f,r,tabs,0,iadd(x,width),iadd(top,1),0,640,font_line_h(f),root,cache,scratch,true)
  var clipboard: Buf=buf_make(0) val copied=cache_copy_embed_selection(cache,clipboard)
  val content=ieq(buf_len(clipboard),5) andalso equal(5,clipboard,"alpha",0)
  val pinned=selected_view_pin(f,r,tabs,root,cache)
  val dragged=cache_embed_selection_dragged(cache) val ink=selection_ink(f,r,tabs,root,cache,scratch)
  val returned=tabs_embed_select(f,r,tabs,0,x,iadd(top,1),0,640,font_line_h(f),root,cache,scratch,true)
  val no_navigation=cache_embed_selection_dragged(cache)
  val ()=cache_clear_embed_selection(cache) val cleared=not(cache_copy_embed_selection(cache,clipboard))
  val ()=buf_free(clipboard)
  val ()=println!("event=embed_selection began=",began," extended=",extended," copy=",content," ink=",ink," cancel=",no_navigation)
in iadd(pinned,iadd(ink,if began andalso candidate andalso extended andalso copied andalso content andalso dragged andalso returned andalso no_navigation andalso cleared then 0 else 1)) end
fun embed_selection_fixture(f: !Font,r: !Rend,root: !Buf,path: !Buf): int = let
  val child=bytes("alpha beta gamma ^a\n") val length=buf_len(child)
  val written=fs_write_buf(buf_cstr(path),child,length) val ()=buf_free(child)
  val parent=bytes("![[child#^a]]\n![[child#^a]]\n") val length=buf_len(parent)
  val document=doc_open() val ()=doc_insert_buf(document,parent,length) val ()=buf_free(parent)
  val tabs=TCons(document,buf_make(0),buf_make(0),0,TNil()) var cache: Cache=CNil() var scratch=buf_make(256)
  val ()=selection_parent_draw(f,r,tabs,root,cache,scratch)
  val errors=selection_drag(f,r,tabs,root,cache,scratch)
  val ()=tabs_free(tabs) val ()=cache_free(cache) val ()=buf_free(scratch)
in iadd(errors,if ieq(written,1) then 0 else 1) end
fun write_note(root: !Buf,name: string,text: string): Buf = let
  val path=selftest_fixture_path(buf_cstr(root),name) val source=bytes(text) val length=buf_len(source)
  val written=fs_write_buf(buf_cstr(path),source,length) val ()=buf_free(source)
  val ()=assertloc(ieq(written,1))
in path end
fun nested_embed_case(f: !Font,r: !Rend,root: !Buf,text: string,expected: int): int = let
  val source=bytes(text) val length=buf_len(source) val d=doc_open()
  val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  var cache: Cache=CNil() var scratch: Buf=buf_make(256)
  val ()=performance_enable(1) val ()=performance_reset()
  val height=prepare_document_layout(f,d,cache,r,root,24,300,ViewRead)
  val loaded=performance_value(PERF_DOCUMENT_LOADS)=g0int2uint_int_ullint(expected)
  val ()=rend_begin(r,640,480) val ()=draw_doc(f,r,d,0,36,640,444,0,font_line_h(f),root,cache,scratch,ViewRead)
  val stats=cache_embed_stats(cache)
  val bounded=ieq(stats.documents,expected) andalso ieq(stats.pending,0) andalso ilt(height,5000)
  val ()=performance_reset() val warm=prepare_document_layout(f,d,cache,r,root,24,300,ViewRead)
  val reused=performance_value(PERF_DOCUMENT_LOADS)=0ULL
  val ()=performance_enable(0) val ()=cache_free(cache) val ()=doc_free(d) val ()=buf_free(scratch)
  val ()=println!("event=nested_embeds expected=",expected," loaded=",loaded," bounded=",bounded," reused=",reused)
in if loaded andalso bounded andalso reused then 0 else 1 end
fun depth_path(root: !Buf,index: int): Buf = let
  var path=selftest_fixture_path(buf_cstr(root),"depth-")
  val ()=buf_push(path,iadd(CHAR_UPPER_A,index)) val ()=buffer_append_string(path,".md")
in path end
fun write_depth_chain{n:nat} .<n>. (left: int(n),root: !Buf,index: int): void =
  if left = 0 then () else let var source: Buf=buf_make(32) val path=depth_path(root,index)
    val ()=if left = 1 then buffer_append_string(source,"bottom\n") else let
      val ()=buffer_append_string(source,"![[depth-") val ()=buf_push(source,iadd(CHAR_UPPER_A,iadd(index,1)))
    in buffer_append_string(source,"]]\n") end
    val length=buf_len(source) val written=fs_write_buf(buf_cstr(path),source,length)
    val ()=assertloc(ieq(written,1)) val ()=buf_free(source) val ()=buf_free(path)
  in write_depth_chain(left-1,root,iadd(index,1)) end
fun remove_depth_chain{n:nat} .<n>. (left: int(n),root: !Buf,index: int): int =
  if left = 0 then 0 else let val path=depth_path(root,index) val removed=fs_unlink(buf_cstr(path))
    val ()=buf_free(path)
  in iadd(if ieq(removed,0) then 0 else 1,remove_depth_chain(left-1,root,iadd(index,1))) end
#include "workspace/embed_scheduler_cases.hats"
#include "workspace/embed_navigation_cases.hats"
fun nested_embeds(f: !Font,r: !Rend,root: !Buf): int = let
  val first=write_note(root,"cycle-a.md","![[cycle-b]]\n") val second=write_note(root,"cycle-b.md","![[cycle-a]]\n")
  val cycle=nested_embed_case(f,r,root,"![[cycle-a]]\n",2)
  val self_path=write_note(root,"cycle-a.md","![[cycle-a]]\n") val ()=buf_free(self_path)
  val self=nested_embed_case(f,r,root,"![[cycle-a]]\n",1)
  val missing=nested_embed_case(f,r,root,"![[missing-target]]\n",0)
  val ()=write_depth_chain(9,root,0) val depth=nested_embed_case(f,r,root,"![[depth-A]]\n",8)
  val removed=remove_depth_chain(9,root,0) val a=fs_unlink(buf_cstr(first)) val b=fs_unlink(buf_cstr(second))
  val ()=buf_free(first) val ()=buf_free(second)
in iadd(cycle+self+missing+depth+removed,if ieq(a,0) andalso ieq(b,0) then 0 else 1) end
fun embedded_documents(f: !Font,r: !Rend): int = let var root=buf_make(512)
  val created=selftest_fixture_open(root)
in if not(created) then let val ()=buf_free(root) in 1 end else let
    val path=selftest_fixture_path(buf_cstr(root),"child.md")
    val errors=iadd(embed_fixture_test(f,r,root,path),embed_selection_fixture(f,r,root,path))
    val nesting=iadd(nested_link_fixture(f,r,root),iadd(nested_embeds(f,r,root),scheduler_fixture(f,r,root)))
    val removed=fs_unlink(buf_cstr(path)) val closed=fs_rmdir(buf_cstr(root))
    val ()=buf_free(path) val ()=buf_free(root)
  in iadd(nesting,iadd(errors,if ieq(removed,0) andalso ieq(closed,0) then 0 else 1)) end end
implement native_visual_layout_cases(f,r) = let val before=mem_live() val d=doc_open()
  val body=test(f,r,d) val markup=markdown(f,r) val hard=hard_lines(f,r)
  val nav=navigation(f,r) val fold=folding_and_task(f,r)
  val errors=body+markup+hard+nav+fold val ()=doc_free(d) val delta=isub(mem_live(),before)
  val scale=iadd(wrap_scale(f,r,64),iadd(wrap_scale(f,r,256),wrap_scale(f,r,1024)))
  val clipping=iadd(paragraph_bidi_rows(f,r),iadd(owned_row_plans(f,r),iadd(nested_clips(r),warm_layout(f,r))))
  val embedded=embedded_documents(f,r)
  val ()=println!("event=native_visual_layout errors=",errors," retained_font_source_bytes=",delta)
  val ()=println!("event=visual_cases body=",body," markdown=",markup," hard=",hard," navigation=",nav," fold=",fold)
in iadd(embedded,iadd(clipping,iadd(errors,scale))) end
