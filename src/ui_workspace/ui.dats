#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "data_ast/doc.sats"
staload "data_image/image.sats"
staload "ui_workspace/ui.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tree.sats"
staload "ui_workspace/ui_search.sats"
staload "ui_workspace/ui_menu.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_render.sats"
staload "ui_workspace/ui_widgets.sats"
staload "ui_workspace/ui_raddbg.sats"
staload "config/conf.sats"

fun iand(a: int, n: int): int = anth_iand(a, n)

datavtype App_ = APP of @{
  vault= Buf, tabs= Tabs, cache= Cache,
  active= int, righti= int, split= int, focus= int, side= int, fontpx= int,
  clip= Buf, menu= int, menux= int, menuy= int, drag= int, dragi= int,
  prompt= int, promptb= Buf, query= Buf, qfocus= int,
  tree= Buf, tmeta= Buf, tn= int, hits= Buf, hmeta= Buf, hn= int,
  sel= int, treedirty= int, paste= int, hitk= int, hiti= int, downx= int, downy= int,
  scratch= Buf, imgpath= Buf, viewmode= int, font_idx= int,
  fpaths= Buf, fnames= Buf, fmeta= Buf, fcnt= int, font_path= Buf,
  vault_select= int, vpaths= Buf, vnames= Buf, vmeta= Buf, vcnt= int
}
assume App = App_

fun save_session_impl(vault: !Buf, font_p: !Buf, font_px: int, viewmode: int, split: int, active: int, ts: !Tabs): void =
  if igt(buf_len(vault), 0) then
    conf_save_session(cstr(vault), cstr(font_p), font_px, viewmode, split, active, ts)
  else ()

fun make_empty_tabs(): Tabs = let
  var title = buf_make(16)
  val () = bstr(title, "Isimsiz")
  var path = buf_make(4)
  val doc = doc_open()
in
  tabs_add(TNil(), doc, path, title)
end

fun tabs_fallback(ts: Tabs): Tabs =
  case+ ts of
  | ~TNil() => make_empty_tabs()
  | ~TCons(d, p, t, s, rest) => TCons(d, p, t, s, rest)

fun load_vault_tabs(target: string, font_path: &Buf >> Buf, out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int): Tabs = let
  var fpx: int = 18
  var vmode: int = 0
  var sp: int = 0
  var act_idx: int = 0
  val loaded_tabs = conf_load_session(target, font_path, fpx, vmode, sp, act_idx, TNil())
  val new_tabs = tabs_fallback(loaded_tabs)
  val () = out_fpx := (if igt(fpx, 0) then fpx else 18)
  val () = out_vm := vmode
  val () = out_sp := sp
  val () = out_act := act_idx
in
  new_tabs
end

fun init_vault_tabs(vb: !Buf, f_vsel: int, font_path: &Buf >> Buf, out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int): Tabs =
  if ieq(buf_len(vb), 0) orelse ieq(f_vsel, 1) then let
    val () = out_fpx := 18
    val () = out_vm := 0
    val () = out_sp := 0
    val () = out_act := 0
  in
    make_empty_tabs()
  end else let
    val () = conf_set_active_vault(cstr(vb))
  in
    load_vault_tabs(cstr(vb), font_path, out_fpx, out_vm, out_sp, out_act)
  end

fun switch_vault_tabs(old_tabs: Tabs, target: string, font_path: &Buf >> Buf, out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int): Tabs = let
  val () = tabs_save_all_physical(old_tabs)
  val () = tabs_free(old_tabs)
in
  load_vault_tabs(target, font_path, out_fpx, out_vm, out_sp, out_act)
end

fun resolve_vault_buffer(vb: &Buf >> Buf, out_vsel: &int >> int): void =
  if ieq(buf_len(vb), 0) then let
    var act = buf_make(256)
    val found = conf_get_active_vault(act)
    val s_act = cstr(act)
    val act_ex = if igt(buf_len(act), 0) then fs_exists(s_act) else 0
    val () = if ieq(found, 1) andalso ieq(act_ex, 1) then let
      val () = bstr(vb, s_act)
      val () = out_vsel := 0
    in
      ()
    end else let
      val () = out_vsel := 1
    in
      ()
    end
    val () = buf_free(act)
  in
    ()
  end else let
    val () = conf_set_active_vault(cstr(vb))
    val () = out_vsel := 0
  in
    ()
  end

fun pick_first_font(fpath: &Buf >> Buf, fpaths: !Buf, fmeta: !Buf, fcnt: int): void =
  if ieq(buf_len(fpath), 0) andalso igt(fcnt, 0) then let
    val poff = buf_get32(fmeta, 0)
    val plen = buf_get32(fmeta, 1)
    val () = bcat(fpath, fpaths, poff, iadd(poff, plen))
  in
    ()
  end else ()

implement app_open(vault) = let
  var vb = buf_make(256)
  val () = bstr(vb, vault)
  var f_vsel: int = 0
  val () = resolve_vault_buffer(vb, f_vsel)

  // Scan fonts dynamically
  var fpaths = buf_make(2048)
  var fnames = buf_make(1024)
  var fmeta = buf_make(512)
  var fcnt: int = 0
  val () = font_scan_fonts("fonts", fpaths, fnames, fmeta, fcnt)

  // Scan vaults for selector modal
  var vpaths = buf_make(2048)
  var vnames = buf_make(512)
  var vmeta = buf_make(512)
  var vcnt: int = 0
  val () = conf_list_vaults(vpaths, vnames, vmeta, vcnt)

  // Initial tab and session state
  var fpath = buf_make(256)
  var fpx: int = 18
  var vmode: int = 0
  var sp: int = 0
  var act_idx: int = 0

  val tabs = init_vault_tabs(vb, f_vsel, fpath, fpx, vmode, sp, act_idx)

  val () = pick_first_font(fpath, fpaths, fmeta, fcnt)
in
  APP(@{
    vault= vb, tabs= tabs, cache= CNil(),
    active= act_idx, righti= 0, split= sp, focus= 0, side= 0, fontpx= fpx,
    clip= buf_make(64), menu= 0, menux= 0, menuy= 0, drag= 0, dragi= ~1,
    prompt= 0, promptb= buf_make(256), query= buf_make(64), qfocus= 0,
    tree= buf_make(64), tmeta= buf_make(64), tn= 0, hits= buf_make(64), hmeta= buf_make(64), hn= 0,
    sel= ~1, treedirty= 1, paste= 0, hitk= 0, hiti= ~1, downx= ~1, downy= ~1,
    scratch= buf_make(4096), imgpath= buf_make(64), viewmode= vmode, font_idx= 0,
    fpaths= fpaths, fnames= fnames, fmeta= fmeta, fcnt= fcnt, font_path= fpath,
    vault_select= f_vsel, vpaths= vpaths, vnames= vnames, vmeta= vmeta, vcnt= vcnt
  })
end

implement app_free(a) = let
  val+ ~APP(s) = a
  val ts2 = tabs_ensure_paths(s.tabs, s.vault)
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, ts2)
  val () = buf_free(s.vault)
  val () = tabs_free(ts2)
  val () = cache_free(s.cache)
  val () = buf_free(s.clip)
  val () = buf_free(s.promptb)
  val () = buf_free(s.query)
  val () = buf_free(s.tree)
  val () = buf_free(s.tmeta)
  val () = buf_free(s.hits)
  val () = buf_free(s.hmeta)
  val () = buf_free(s.scratch)
  val () = buf_free(s.imgpath)
  val () = buf_free(s.fpaths)
  val () = buf_free(s.fnames)
  val () = buf_free(s.fmeta)
  val () = buf_free(s.font_path)
  val () = buf_free(s.vpaths)
  val () = buf_free(s.vnames)
in
  buf_free(s.vmeta)
end

fun pane_of(sfocus: int, active: int, righti: int): int =
  if ieq(sfocus, 0) then active else righti
fun draw_side(f: !Font, r: !Rend, a: !App, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = rend_scissor(r, 0, 36, 280, isub(h, 36))
      val () = rend_rect(r, 0, 36, 280, isub(h, 36), col_side())
      val () = ui_divider(r, 0, 64, 280, 0)
      val () = ui_divider(r, 279, 36, isub(h, 36), 1)
      val title =
        if ieq(s.side, 1) then "Dosya Gezgini Aç/Kapa"
        else if ieq(s.side, 2) then "Genel Arama"
        else "Ayarlar"
      val _ds = draw_s(f, r, 12, 44, title, col_heading())
      val () = if ieq(s.treedirty, 1) andalso ieq(s.side, 1) then let
        val () = bclear(s.tree)
        val () = bclear(s.tmeta)
        val () = s.tn := 0
        val () = scan_dir(s.vault, 0, s.tmeta, s.tree, s.tn)
        val () = if ige(s.sel, s.tn) then s.sel := ~1 else ()
      in
        s.treedirty := 0
      end else ()
    in
      if ieq(s.side, 2) then let
        val qn = buf_len(s.query)
        val () = ui_line_edit_draw(f, r, 8, 68, 264, 24, s.query, qn, qn, s.qfocus, "Aramak icin yazin...")
        var row: int = 0
      in
        while (ilt(row, s.hn) andalso ilt(row, 24)) (
          if ilt(buf_get32(s.hmeta, imul(row, 4)), 0) then let
            val off = buf_get32(s.hmeta, iadd(imul(row, 4), 1))
            val n = buf_get32(s.hmeta, iadd(imul(row, 4), 2))
            val _y = hit_text(s.hits, off, n, f, r, 12, iadd(100, imul(row, 18)), col_accent())
          in
          end else let
            val moff = buf_get32(s.hmeta, imul(row, 4))
            val off = buf_get32(s.hmeta, iadd(imul(row, 4), 1))
            val n = buf_get32(s.hmeta, iadd(imul(row, 4), 2))
            val ml = buf_get32(s.hmeta, iadd(imul(row, 4), 3))
            val y = iadd(100, imul(row, 18))
            val a1 = hit_text(s.hits, off, moff, f, r, 20, y, col_muted())
            val a2 = hit_text(s.hits, iadd(off, moff), ml, f, r, iadd(20, a1), y, col_hightxt())
            val _a3 = hit_text(s.hits, iadd(off, iadd(moff, ml)), isub(n, iadd(moff, ml)), f, r, iadd(20, iadd(a1, a2)), y, col_muted())
          in
          end;
          row := iadd(row, 1)
        );
        rend_scissor_off(r);
        fold@(a)
      end else if ieq(s.side, 1) then let
        var row: int = 0
      in
        while (ilt(row, s.tn) andalso ilt(row, 28)) (
          let
            val depth = buf_get32(s.tmeta, imul(row, 4))
            val isdir = buf_get32(s.tmeta, iadd(imul(row, 4), 1))
            val off = buf_get32(s.tmeta, iadd(imul(row, 4), 2))
            val n = buf_get32(s.tmeta, iadd(imul(row, 4), 3))
            var base = buf_make(8)
            val () = bcat(base, s.tree, off, iadd(off, n))
            val () = base_name(base, s.scratch)
            val icon = if ieq(isdir, 1) then UI_ICON_FOLDER else UI_ICON_FILE
            val is_sel = if ieq(s.sel, row) then 1 else 0
            val () = rd_cell(f, r, 6, iadd(72, imul(row, 18)), 268, 18, depth, isdir, isdir, icon, cstr(s.scratch), "", is_sel, 0)
            val () = buf_free(base)
          in
          end;
          row := iadd(row, 1)
        );
        rend_scissor_off(r);
        fold@(a)
      end else let
        val _ds = draw_s(f, r, 12, 76, "Kasa", col_muted())
        val vn = buf_len(s.vault)
        val vlabel = if igt(vn, 0) then buf_ptr(s.vault) else c_str_ptr("(Secilmedi)")
        val _p = font_draw(f, r, 12, 94, vlabel, imin(if igt(vn, 0) then vn else 10, 28), col_text())
        val () = ui_button(f, r, 12, 122, 150, 22, "Kasayi Degistir", 0, 0)

        val _ds = draw_s(f, r, 12, 154, "Yazi Boyutu (tikla)", col_text())
        val pxlab = if ieq(s.fontpx, 16) then "16 px" else if ieq(s.fontpx, 20) then "20 px" else "18 px"
        val _px = ui_badge(f, r, 190, 152, pxlab, col_bar(), col_accent())

        val _ds = draw_s(f, r, 12, 186, "Yazi Tipi (fonts/)", col_text())
        var fi: int = 0
      in
        while (ilt(fi, s.fcnt) andalso ilt(fi, 12)) (
          let
            var pbuf = buf_make(256)
            var nbuf = buf_make(64)
            val fy = iadd(210, imul(fi, 22))
            val poff = buf_get32(s.fmeta, imul(fi, 4))
            val plen = buf_get32(s.fmeta, iadd(imul(fi, 4), 1))
            val noff = buf_get32(s.fmeta, iadd(imul(fi, 4), 2))
            val nlen = buf_get32(s.fmeta, iadd(imul(fi, 4), 3))
            val () = bcat(pbuf, s.fpaths, poff, iadd(poff, plen))
            val () = bcat(nbuf, s.fnames, noff, iadd(noff, nlen))
            val is_sel = if ieq(c_strcmp(cstr(pbuf), cstr(s.font_path)), 0) then 1 else 0
            val f_icon = if ieq(is_sel, 1) then UI_ICON_CHECK else UI_ICON_CHECK_EMPTY
            val () = rd_cell(f, r, 12, fy, 256, 22, 0, 0, 0, f_icon, cstr(nbuf), "", is_sel, 0)
            val () = buf_free(pbuf)
            val () = buf_free(nbuf)
          in
            fi := iadd(fi, 1)
          end
        );
        rend_scissor_off(r);
        fold@(a)
      end
    end
fun ui_draw_menu(f: !Font, r: !Rend, a: !App): void =
  case+ a of
  | @APP(s) => let
      val () = draw_menu(f, r, s.menu, s.menux, s.menuy)
    in
      fold@(a)
    end

fun top_btn_w(f: !Font, r: !Rend, s: string, min_w: int): int = let
  val tw = font_width(f, r, c_str_ptr(s), c_strlen(s))
in
  imax(min_w, iadd(tw, 24))
end

fun draw_panes(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = if ieq(s.font_idx, 0) andalso igt(buf_len(s.font_path), 0) then let
        val _ok = font_use_file(f, cstr(s.font_path))
        val () = font_set_px(f, s.fontpx)
        val () = s.font_idx := 1
      in
        ()
      end else ()
      val sidew = if igt(s.side, 0) then 280 else 0
      val ox = sidew
      val pw = isub(w, sidew)
      val () = font_set_px(f, s.fontpx)
      val lh = font_line_h(f)
      val half = if ieq(s.split, 1) then idiv(pw, 2) else pw

      val top_w = 96
      val x1 = 8
      val x2 = iadd(x1, iadd(top_w, 6))
      val x3 = iadd(x2, iadd(top_w, 6))
      val tab_sep_x = iadd(x3, iadd(top_w, 14))
      val tab_x0 = iadd(tab_sep_x, 16)

      val btxt = if ieq(s.viewmode, 0) then "Düzenle" else "Okuma"
      val bw = 96
      val bx = isub(w, iadd(bw, 10))

      val () = rend_rect(r, 0, 0, w, h, col_bg())
      val () = rend_rect(r, 0, 0, w, 36, col_bar())
      val () = ui_divider(r, 0, 35, w, 0)

      val () = rd_icon_button(f, r, UI_ICON_FOLDER, "Gezgin", x1, 4, top_w, 28, if ieq(s.side, 1) then 1 else 0, 0)
      val () = rd_icon_button(f, r, UI_ICON_SEARCH, "Arama", x2, 4, top_w, 28, if ieq(s.side, 2) then 1 else 0, 0)
      val () = rd_icon_button(f, r, UI_ICON_SETTINGS, "Ayarlar", x3, 4, top_w, 28, if ieq(s.side, 3) then 1 else 0, 0)
      val () = ui_divider(r, tab_sep_x, 8, 20, 1)

      val () = ui_button(f, r, bx, 4, bw, 28, btxt, 0, if ieq(s.viewmode, 0) then 1 else 0)

      val ts = s.tabs
      val () = s.tabs := TNil()
      val mark = if ieq(s.focus, 0) then s.active else s.righti
      val ts2 = draw_tabrow(f, r, ts, tab_x0, mark, 0)
      val ts3 = draw_focus(f, r, ts2, s.active, ox, 36, half, isub(h, 36), lh, s.vault, s.cache, s.scratch, 0, s.viewmode)
      val ts4 = draw_right(f, r, ts3, s.split, s.righti, iadd(ox, half), 36, half, isub(h, 36), lh, s.vault, s.cache, s.scratch, s.viewmode)
      val ph = s.tabs
      val () = s.tabs := ts4
      val () = tabs_free(ph)
      val () = if ieq(s.split, 1) then ui_divider(r, iadd(ox, half), 36, isub(h, 36), 1) else ()
    in
      fold@(a)
    end

fun ui_draw_prompt(f: !Font, r: !Rend, a: !App): void =
  case+ a of
  | @APP(s) => let
      val () = draw_prompt(f, r, s.promptb, s.prompt)
    in
      fold@(a)
    end

fun draw_vault_select(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = if ieq(s.vault_select, 1) then let
        val () = rend_rect(r, 0, 0, w, h, col_overlay())
        val mw = 520
        val mh = 360
        val mx = idiv(isub(w, mw), 2)
        val my = idiv(isub(h, mh), 2)
        val () = ui_pane_begin(r, mx, my, mw, mh, col_bg())
        val () = ui_pane_draw_header(f, r, mx, my, mw, "Kasa Secimi / Vault Secimi", if igt(buf_len(s.vault), 0) then 1 else 0)

        val _ds = draw_s(f, r, iadd(mx, 16), iadd(my, 44), "Mevcut kasalardan birini secin veya yeni kasa olusturun:", col_muted())

        var vi: int = 0
        val list_max = imin(s.vcnt, 6)
        val () = while (ilt(vi, list_max)) (
          let
            var nbuf = buf_make(64)
            var pbuf = buf_make(256)
            val ry = iadd(my, iadd(68, imul(vi, 26)))
            val poff = buf_get32(s.vmeta, imul(vi, 4))
            val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
            val noff = buf_get32(s.vmeta, iadd(imul(vi, 4), 2))
            val nlen = buf_get32(s.vmeta, iadd(imul(vi, 4), 3))
            val () = bcat(pbuf, s.vpaths, poff, iadd(poff, plen))
            val () = bcat(nbuf, s.vnames, noff, iadd(noff, nlen))
            val is_curr = if ieq(c_strcmp(cstr(pbuf), cstr(s.vault)), 0) then 1 else 0
            val () = rd_cell(f, r, iadd(mx, 16), ry, isub(mw, 32), 24, 0, 0, 0, UI_ICON_FOLDER, cstr(nbuf), cstr(pbuf), is_curr, 0)
            val () = buf_free(nbuf)
            val () = buf_free(pbuf)
          in
            vi := iadd(vi, 1)
          end
        )

        val iy = iadd(my, 248)
        val _di = draw_s(f, r, iadd(mx, 16), iy, "Yeni Kasa Konumu (Klasor Yolu):", col_text())
        val qlen = buf_len(s.promptb)
        val () = ui_line_edit_draw(f, r, iadd(mx, 16), iadd(iy, 20), isub(mw, 32), 26, s.promptb, qlen, qlen, 1, "ornegin: /home/kullanici/Notlar")

        val by = iadd(my, 310)
        val () = ui_button(f, r, iadd(mx, 16), by, 140, 30, "Ac / Olustur", 0, 1)
        val () = if igt(buf_len(s.vault), 0) then ui_button(f, r, isub(iadd(mx, mw), 116), by, 100, 30, "Iptal", 0, 0) else ()
      in
      end else ()
    in
      fold@(a)
    end

implement app_draw(a, f, r, w, h) = let
  val () = draw_panes(f, r, a, w, h)
  val show = let
    val v = case+ a of
      | @APP(s) => let val k = s.side in fold@(a); k end
  in
    v
  end
  val () = if igt(show, 0) then draw_side(f, r, a, h) else ()
  val () = ui_draw_prompt(f, r, a)
  val () = ui_draw_menu(f, r, a)
in
  draw_vault_select(f, r, a, w, h)
end
fun find_wiki(doc: !Doc, caret: int, k: int): int =
  if ige(k, doc_nnodes(doc)) then ~1
  else if ile(doc_get(doc, k, 1), caret) andalso ilt(caret, doc_get(doc, k, 2)) andalso ieq(doc_get(doc, k, 0), 16) then k
  else find_wiki(doc, caret, iadd(k, 1))

fun open_or(rest: Tabs, owned: Buf, go: int): Tabs =
  if ieq(go, 1) then tabs_open(rest, owned)
  else let
    val () = buf_free(owned)
  in
    rest
  end

fun take_if(doc: !Doc, w: int, rel: &Buf >> _, go: int): void =
  if ieq(go, 1) then take_path(doc, w, rel) else touchb(rel)

fun wiki_here(doc: !Doc, rest: Tabs, vault: !Buf): Tabs = let
  val _ni = node_covering(doc, 0, 0, 0, 0, ~1)
  var rel = buf_make(8)
  var full = buf_make(8)
  var shown = buf_make(8)
  val w = find_wiki(doc, doc_caret(doc), 0)
  val () = take_if(doc, w, rel, iif(ige(w, 0), 1, 0))
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
  val owned = bcopy(shown)
  val restw = open_or(rest, owned, iif(ige(w, 0), 1, 0))
  val () = buf_free(rel)
  val () = buf_free(full)
in
  let
    val () = buf_free(shown)
  in
    restw
  end
end

fun wiki_open(ts: Tabs, idx: int, vault: !Buf, i: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) =>
      TCons(doc, path, title, sc, wiki_arm(ieq(i, idx), doc, rest, idx, vault, i))
and wiki_arm(stop: bool, doc: !Doc, rest: Tabs, idx: int, vault: !Buf, i: int): Tabs =
  if stop then wiki_here(doc, rest, vault) else wiki_open(rest, idx, vault, iadd(i, 1))

fun close_active_tab(ts: Tabs, idx: int): Tabs = let
  val ts2 = tabs_drop(ts, idx)
in
  if ieq(tabs_len(ts2), 0) then let
    val d = doc_open()
    var p = buf_make(4)
    var t = buf_make(16)
    val () = bstr(t, "Yeni Not")
  in
    tabs_add(ts2, d, p, t)
  end else ts2
end

fun new_empty_tab(ts: Tabs): Tabs = let
  val d = doc_open()
  var p = buf_make(4)
  var t = buf_make(16)
  val () = bstr(t, "Yeni Not")
in
  tabs_add(ts, d, p, t)
end

fun key_code(ev: &event, act: int): int =
  if ieq(act, 0) then
    if ieq(key_is(ev, 10), 1) then 41 else 0
  else if ieq(ctrl_on(ev), 1) then let
    val sh = shift_on(ev)
  in
    if ieq(key_is(ev, 0), 1) then (if ieq(sh, 1) then 45 else 43)
    else if ieq(key_is(ev, 1), 1) then (if ieq(sh, 1) then 46 else 44)
    else if ieq(key_is(ev, 4), 1) then 47
    else if ieq(key_is(ev, 5), 1) then 48
    else if ieq(key_is(ev, 6), 1) then (if ieq(sh, 1) then 51 else 49)
    else if ieq(key_is(ev, 7), 1) then (if ieq(sh, 1) then 52 else 50)
    else if ieq(key_is(ev, 9), 1) then (if ieq(sh, 1) then 58 else 57)
    else let
      val c = key_char(ev)
    in
      if ieq(c, 122) then // 'z'
        if ieq(sh, 1) then 17 else 16
      else if ieq(c, 121) then 17 // 'y'
      else if ieq(c, 115) orelse ieq(c, 83) orelse ieq(key_is(ev, 15), 1) orelse ieq(key_is(ev, 20), 1) then 15 // 's'
      else if ieq(c, 97) then 9   // 'a'
      else if ieq(c, 99) then 12  // 'c'
      else if ieq(c, 120) then 14 // 'x'
      else if ieq(c, 118) then 13 // 'v'
      else if ieq(c, 102) then 35 // 'f'
      else if ieq(c, 112) orelse ieq(c, 111) then 35 // 'p', 'o'
      else if ieq(c, 119) then 36 // 'w'
      else if ieq(c, 116) then 37 // 't'
      else if ieq(c, 110) then    // 'n'
        if ieq(sh, 1) then 39 else 38
      else if ieq(c, 101) then 40 // 'e'
      else if ieq(c, 98) then 18  // 'b'
      else if ieq(c, 105) then 19 // 'i'
      else if ieq(c, 107) then 20 // 'k'
      else 0 // ignore unknown Ctrl combinations; never treat as printable text
    end
  end else if ieq(key_is(ev, 10), 1) then 41 // Escape
  else if ieq(key_is(ev, 0), 1) then (if ieq(shift_on(ev), 1) then 21 else 1)       // Left
  else if ieq(key_is(ev, 1), 1) then (if ieq(shift_on(ev), 1) then 22 else 2)       // Right
  else if ieq(key_is(ev, 2), 1) then (if ieq(shift_on(ev), 1) then 23 else 3)       // Up
  else if ieq(key_is(ev, 3), 1) then (if ieq(shift_on(ev), 1) then 24 else 4)       // Down
  else if ieq(key_is(ev, 6), 1) then (if ieq(shift_on(ev), 1) then 25 else 5)       // Home
  else if ieq(key_is(ev, 7), 1) then (if ieq(shift_on(ev), 1) then 26 else 6)       // End
  else if ieq(key_is(ev, 41), 1) then (if ieq(shift_on(ev), 1) then 55 else 53)     // Page Up
  else if ieq(key_is(ev, 42), 1) then (if ieq(shift_on(ev), 1) then 56 else 54)     // Page Down
  else if ieq(key_is(ev, 4), 1) then 7       // Backspace
  else if ieq(key_is(ev, 5), 1) then 8       // Delete
  else if ieq(key_is(ev, 8), 1) then 30      // Enter
  else if ieq(key_is(ev, 9), 1) then 28      // Tab
  else 31                                    // Normal typing

fun apply_key(ts: Tabs, idx: int, cmd: int, vault: !Buf, clip: &Buf >> _, scratch: &Buf >> _, p: !Plat, paste: &int >> _): Tabs =
  if ieq(cmd, 15) then tabs_ensure_paths(ts, vault)
  else if ieq(cmd, 12) then let
      val () = tabs_copy(ts, idx, clip)
      val () = plat_own(p, 0)
      val () = plat_own(p, 1)
    in
      ts
    end else if ieq(cmd, 14) then let
      val () = tabs_copy(ts, idx, clip)
      val () = plat_own(p, 0)
      val () = plat_own(p, 1)
      val ts2 = tabs_cmd(ts, idx, 10)
      val () = tabs_sync_vfs(ts2, idx)
    in
      ts2
    end else if ieq(cmd, 13) then let
      val () = paste := 1
      val () = plat_paste(p, 0)
    in
      ts
    end else if ieq(cmd, 30) then let
      val () = buf_set(scratch, 0, 10)
      val ts2 = tabs_ins(ts, idx, buf_ptr(scratch), 1)
      val () = tabs_sync_vfs(ts2, idx)
    in
      ts2
    end else if ieq(cmd, 41) then tabs_cmd(ts, idx, 11)
    else if igt(cmd, 0) andalso ilt(cmd, 57) then let
      val ts2 = tabs_cmd(ts, idx, cmd)
      val is_edit = if ieq(cmd, 7) orelse ieq(cmd, 8) orelse ieq(cmd, 10)
                    orelse ieq(cmd, 16) orelse ieq(cmd, 17) orelse ieq(cmd, 18)
                    orelse ieq(cmd, 19) orelse ieq(cmd, 20) orelse ieq(cmd, 28)
                    orelse ieq(cmd, 47) orelse ieq(cmd, 48)
                    then 1 else 0
      val () = if ieq(is_edit, 1) then tabs_sync_vfs(ts2, idx) else ()
    in
      ts2
    end else ts

fun filter_text(b: !Buf, n: int): int = let
  val p = buf_ptr(b)
  var i: int = 0
  var has_esc: int = 0
in
  while (ilt(i, n)) (
    let
      val by = mem_byte(p, n, i)
    in
      if ieq(by, 27) then has_esc := 1 else ();
      i := iadd(i, 1)
    end
  );
  if ieq(has_esc, 1) then 0
  else let
    var j: int = 0
    var w: int = 0
  in
    while (ilt(j, n)) (
      let
        val byte = mem_byte(p, n, j)
      in
        if (ige(byte, 32) andalso ine(byte, 127)) orelse ieq(byte, 9) orelse ieq(byte, 10) then (
          mem_set_byte(p, n, w, byte);
          w := iadd(w, 1)
        ) else ();
        j := iadd(j, 1)
      end
    );
    w
  end
end

fun key_dispatch(ts: Tabs, idx: int, cmd: int, vault: !Buf, clip: &Buf >> _, scratch: &Buf >> _, p: !Plat, paste: &int >> _, ev: &event): Tabs =
  if ieq(cmd, 31) then
    if ieq(ctrl_on(ev), 1) then ts
    else let
      val sp = buf_ptr(scratch)
      val raw_n = ev_text(ev, sp, buf_cap(scratch))
      val n = filter_text(scratch, raw_n)
    in
      if igt(n, 0) then let
        val ts2 = tabs_ins(ts, idx, buf_ptr(scratch), n)
        val () = tabs_sync_vfs(ts2, idx)
      in
        ts2
      end else ts
    end
  else apply_key(ts, idx, cmd, vault, clip, scratch, p, paste)

fun row_if(tree: !Buf, meta: !Buf, sel: int, cur: &Buf >> _, go: int): void =
  if ieq(go, 1) then row_path(tree, meta, sel, cur) else touchb(cur)

fun fill_dir(dir: &Buf >> _, cur: !Buf, vault: !Buf, use_dir: int, sel: int): void =
  if ieq(use_dir, 1) andalso igt(buf_len(cur), 0) then let
    val n = buf_len(cur)
  in
    bcat(dir, cur, 0, n)
  end else if ige(sel, 0) andalso igt(buf_len(cur), 0) then let
    val () = dirname_of(cur, dir)
    val () = if ieq(buf_len(dir), 0) andalso igt(buf_len(vault), 0) then bcat(dir, vault, 0, buf_len(vault)) else ()
  in
  end
  else let
    val n = buf_len(vault)
    val _c = buf_len(cur)
  in
    if igt(n, 0) then bcat(dir, vault, 0, n)
    else let
      var cwd_buf = buf_make(512)
      val _cw = c_cwd(buf_ptr(cwd_buf), 511)
      val () = bstr(dir, ptr_string(buf_ptr(cwd_buf)))
    in
      buf_free(cwd_buf)
    end
  end

fun copy_if(ts: !Tabs, idx: int, clip: &Buf >> _, go: int): void =
  if ieq(go, 1) then tabs_copy(ts, idx, clip) else touchb(clip)

fun cmd_if(ts: Tabs, idx: int, cmd: int, go: int): Tabs =
  if ieq(go, 1) then tabs_cmd(ts, idx, cmd) else ts

fun drop_if(ts: Tabs, ti: int, go: int): Tabs =
  if ieq(go, 1) then tabs_drop(ts, ti) else ts

fun tab_keep_one(ts: Tabs, close: int): Tabs =
  if ieq(close, 1) then
    if ieq(tabs_len(ts), 0) then new_empty_tab(ts) else ts
  else ts

fun open_row(ts: Tabs, tree: !Buf, meta: !Buf, row: int, go: int): Tabs =
  if ieq(go, 1) then let
    var cur = buf_make(8)
    val () = row_path(tree, meta, row, cur)
    val owned = bcopy(cur)
    val () = buf_free(cur)
  in
    tabs_open(ts, owned)
  end else ts

fun click_go(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, lh: int, scratch: &Buf >> _, keep: int, hitk: &int >> _, hiti: &int >> _, go: int): Tabs =
  if ieq(go, 1) then tabs_click(f, r, ts, idx, x, y, ox, pw, 0, lh, scratch, keep, hitk, hiti, 0)
  else let
    val () = touchb(scratch)
  in
    ts
  end

fun wiki_go(ts: Tabs, idx: int, vault: !Buf, go: int): Tabs =
  if ieq(go, 1) then wiki_open(ts, idx, vault, 0) else ts

fun read_all(path: !Buf, dst: &Buf >> _): void = let
  val p = cstr(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 8000000 then touchb(dst)
  else let
    val fd = fs_open_read(p)
    val () = bclear(dst)
    val () = buf_ensure(dst, iadd(sz, 1))
    val n = read_or(dst, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
  in
    buf_set_len(dst, if igt(n, 0) then n else 0)
  end
end

fun fill_node_path(doc: !Doc, ni: int, vault: !Buf, dst: &Buf >> _): void = let
  var rel = buf_make(64)
  var full = buf_make(160)
  val () = take_if(doc, ni, rel, iif(ige(ni, 0), 1, 0))
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, dst)
  val () = buf_free(rel)
in
  buf_free(full)
end

fun copy_node_file(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void =
  case+ ts of
  | @TNil() => let
      val () = touchb(clip)
    in
      fold@(ts)
    end
  | @TCons(doc, path, title, sc, rest) => let
      val () = copy_node_arm(ieq(i, idx), doc, rest, idx, ni, vault, clip, i)
      val _a = buf_len(path)
      val _b = buf_len(title)
      val _c = sc
    in
      fold@(ts)
    end
and copy_node_arm(stop: bool, doc: !Doc, rest: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void =
  if stop then let
    var shown = buf_make(160)
    val () = fill_node_path(doc, ni, vault, shown)
    val () = read_all(shown, clip)
  in
    buf_free(shown)
  end else copy_node_file(rest, idx, ni, vault, clip, iadd(i, 1))

fun clip_image(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, go: int): void =
  if ieq(go, 1) then copy_node_file(ts, idx, ni, vault, clip, 0) else touchb(clip)

fun erase_span(doc: !Doc, a: int, b: int): void = let
  val () = doc_set_caret(doc, a, 0)
  val () = doc_set_caret(doc, b, 1)
in
  doc_delete(doc)
end

fun span_if(doc: !Doc, a: int, b: int, go: int): void =
  if ieq(go, 1) then erase_span(doc, a, b)
  else let
    val _n = doc_len(doc)
  in
    ()
  end

fun node_field(doc: !Doc, ni: int, field: int): int =
  if ige(ni, 0) then doc_get(doc, ni, field)
  else let
    val _n = doc_len(doc)
  in
    0
  end

fun del_node(ts: Tabs, idx: int, ni: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val a = node_field(doc, ni, 1)
      val b = node_field(doc, ni, 2)
      val go = if ieq(idx, 0) andalso ige(ni, 0) then 1 else 0
      val () = span_if(doc, a, b, go)
    in
      TCons(doc, path, title, sc, del_rest(ieq(idx, 0), rest, idx, ni))
    end
and del_rest(stop: bool, rest: Tabs, idx: int, ni: int): Tabs =
  if stop then rest else del_node(rest, isub(idx, 1), ni)

fun del_go(ts: Tabs, idx: int, ni: int, go: int): Tabs =
  if ieq(go, 1) then del_node(ts, idx, ni) else ts

fun strip_into(src: !Buf, dst: &Buf >> _, i: int): void =
  if ige(i, buf_len(src)) then touchb(dst)
  else let
    val c = buf_get(src, i)
    val drop = if ieq(c, 42) orelse ieq(c, 61) orelse ieq(c, 91) orelse ieq(c, 93) orelse ieq(c, 96) then 1 else 0
    val () = push_if(dst, iif(ieq(drop, 1), 0, 1), c)
  in
    strip_into(src, dst, iadd(i, 1))
  end

fun clear_doc(doc: !Doc): void = let
  val a0 = doc_anchor(doc)
  val c0 = doc_caret(doc)
  val lo = imin(a0, c0)
  val hi = imax(a0, c0)
in
  if ieq(lo, hi) then let
    val _n = doc_len(doc)
  in
    ()
  end else let
    var raw = buf_make(iadd(isub(hi, lo), 2))
    var out = buf_make(iadd(isub(hi, lo), 2))
    val cap = buf_cap(raw)
    val n = doc_slice(doc, lo, hi, buf_ptr(raw), cap)
    val () = buf_set_len(raw, n)
    val () = strip_into(raw, out, 0)
    val () = erase_span(doc, lo, hi)
    val m = buf_len(out)
    val () = doc_insert(doc, buf_ptr(out), m)
    val () = buf_free(raw)
  in
    buf_free(out)
  end
end

fun clear_node(ts: Tabs, idx: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = if ieq(idx, 0) then clear_doc(doc) else let
        val _n = doc_len(doc)
      in
        ()
      end
    in
      TCons(doc, path, title, sc, clear_rest(ieq(idx, 0), rest, idx))
    end
and clear_rest(stop: bool, rest: Tabs, idx: int): Tabs =
  if stop then rest else clear_node(rest, isub(idx, 1))

fun clear_go(ts: Tabs, idx: int, go: int): Tabs =
  if ieq(go, 1) then clear_node(ts, idx) else ts

fun toggle_go(ts: Tabs, idx: int, ni: int, go: int): Tabs =
  if ieq(go, 1) then tabs_toggle(ts, idx, ni) else ts

fun toggle_task_go(ts: Tabs, idx: int, ni: int, go: int): Tabs =
  if ieq(go, 1) then let
    val ts2 = tabs_toggle_task(ts, idx, ni)
    val () = tabs_sync_vfs(ts2, idx)
  in
    ts2
  end else ts

fun open_hit(ts: Tabs, hmeta: !Buf, hits: !Buf, srow: int, go: int): Tabs =
  if ieq(go, 1) then let
    var hitfile = buf_make(16)
    val () = find_hit_file(hmeta, hits, srow, hitfile)
    val owned = bcopy(hitfile)
    val () = buf_free(hitfile)
  in
    tabs_open(ts, owned)
  end else ts

fun open_created_file(ts: Tabs, dir: !Buf, name: !Buf, kind: int): Tabs =
  if ieq(kind, 1) then let
    var new_file = buf_make(8)
    val () = child_path(dir, name, new_file)
    val has_dot = has_dot_char(name, 0)
    val need_md = if ieq(has_dot, 0) then 1 else 0
    val () = bstr_if(new_file, need_md, ".md")
  in
    tabs_open(ts, new_file)
  end else ts

fun apply_tab_cmd(ts: Tabs, cmd: int, idx: int): Tabs =
  if ieq(cmd, 36) then close_active_tab(ts, idx)
  else if ieq(cmd, 37) then new_empty_tab(ts)
  else ts

fun hit_open_if(ts: Tabs, hmeta: !Buf, hits: !Buf, hn: int, qf: int, qr: int): Tabs =
  if ieq(qf, 1) andalso ieq(qr, 2) andalso igt(hn, 0) then open_hit(ts, hmeta, hits, 0, 1) else ts

fun on_key(a: !App, p: !Plat, f: !Font, ev: &event): void =
  case+ a of
  | @APP(s) =>
      if ieq(s.vault_select, 1) then let
        val vr = edit_line(s.promptb, ev, s.scratch)
        val () = if ieq(vr, 2) andalso igt(buf_len(s.promptb), 0) then let
          val target = cstr(s.promptb)
          val _mk = fs_mkdir(target)
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          val () = bclear(s.vault)
          val () = bstr(s.vault, target)
          val () = conf_set_active_vault(target)
          val old_t = s.tabs
          val () = s.tabs := TNil()
          var n_fpx: int = 18
          var n_vm: int = 0
          var n_sp: int = 0
          var n_act: int = 0
          val new_t = switch_vault_tabs(old_t, target, s.font_path, n_fpx, n_vm, n_sp, n_act)
          val ph = s.tabs
          val () = s.tabs := new_t
          val () = tabs_free(ph)
          val () = s.fontpx := n_fpx
          val () = s.viewmode := n_vm
          val () = s.split := n_sp
          val () = s.active := n_act
          val () = s.righti := 0
          val () = s.treedirty := 1
          val () = bclear(s.promptb)
          val () = s.vault_select := 0
        in
          ()
        end else if ieq(vr, 3) andalso igt(buf_len(s.vault), 0) then let
          val () = s.vault_select := 0
        in
          ()
        end else ()
      in
        fold@(a)
      end else let
        val act = if ieq(s.prompt, 0) andalso ieq(s.qfocus, 0) then 1 else 0
        val pr = if igt(s.prompt, 0) then edit_line(s.promptb, ev, s.scratch) else 0
        val qr = if ieq(s.qfocus, 1) andalso ieq(s.prompt, 0) then edit_line(s.query, ev, s.scratch) else 0
        val () = if ieq(s.qfocus, 1) andalso ieq(qr, 0) then refresh_search(s.vault, s.query, s.hits, s.hmeta, s.hn) else ()
        val () = if ieq(s.qfocus, 1) andalso ieq(qr, 3) then s.qfocus := 0 else ()
        val hit_go = if ieq(s.qfocus, 1) andalso ieq(qr, 2) andalso igt(s.hn, 0) then 1 else 0
        val () = if ieq(hit_go, 1) then let
            val () = s.qfocus := 0
            val () = s.active := 0
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else ()
        val () = if ieq(pr, 2) andalso igt(buf_len(s.promptb), 0) then let
            var dir = buf_make(8)
            var cur = buf_make(8)
            val sel_valid = if ige(s.sel, 0) andalso ilt(s.sel, s.tn) then 1 else 0
            val () = row_if(s.tree, s.tmeta, s.sel, cur, sel_valid)
            val use_dir = if ieq(sel_valid, 1) andalso ieq(buf_get32(s.tmeta, iadd(imul(s.sel, 4), 1)), 1) then 1 else 0
            val () = fill_dir(dir, cur, s.vault, use_dir, if ieq(sel_valid, 1) then s.sel else ~1)
            val prompt_kind = s.prompt
            val () = act_prompt(dir, cur, s.promptb, prompt_kind)
            val ts_curr = s.tabs
            val () = s.tabs := TNil()
            val ts_next = open_created_file(ts_curr, dir, s.promptb, prompt_kind)
            val ph = s.tabs
            val () = s.tabs := ts_next
            val () = tabs_free(ph)
            val () = if ieq(prompt_kind, 1) then s.active := 0 else ()
            val () = s.prompt := 0
            val () = bclear(s.promptb)
            val () = s.treedirty := 1
            val () = buf_free(dir)
          in
            buf_free(cur)
          end else if ieq(pr, 2) then let
            val () = s.prompt := 0
            val () = bclear(s.promptb)
          in
          end else ()
        val () = if ieq(pr, 3) then let
            val () = s.prompt := 0
          in
            bclear(s.promptb)
          end else ()
        val cmd = key_code(ev, act)
        val () =
          if ieq(cmd, 35) then let
            val () = s.side := 2
            val () = s.qfocus := 1
          in
            bclear(s.query)
          end else if ieq(cmd, 38) then let
            val () = s.prompt := 1
          in
            bclear(s.promptb)
          end else if ieq(cmd, 39) then let
            val () = s.prompt := 2
          in
            bclear(s.promptb)
          end else if ieq(cmd, 40) then let
            val vm = if ieq(s.viewmode, 0) then 1 else 0
            val () = s.viewmode := vm
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else if ieq(cmd, 41) then let
            val () = s.menu := 0
            val () = s.qfocus := 0
            val () = s.prompt := 0
          in
            bclear(s.promptb)
          end else ()
        val ts0 = s.tabs
        val () = s.tabs := TNil()
        val ts = hit_open_if(ts0, s.hmeta, s.hits, s.hn, hit_go, 2)
        val idx = if ieq(s.focus, 0) then s.active else s.righti
        var ts_inter: Tabs = apply_tab_cmd(ts, cmd, idx)
        val () = if ieq(cmd, 36) orelse ieq(cmd, 37) then let
            val max_i = isub(tabs_len(ts_inter), 1)
            val () = if ieq(cmd, 37) then s.active := max_i
                     else s.active := imax(0, imin(max_i, s.active))
            val () = s.righti := imax(0, imin(max_i, s.righti))
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else if ieq(cmd, 57) then let
            val ntabs = tabs_len(ts_inter)
            val () = if igt(ntabs, 1) then let
                val next_i = iadd(s.active, 1)
                val cur_i = if ige(next_i, ntabs) then 0 else next_i
                val () = s.active := cur_i
                val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
              in
              end else ()
          in
          end else if ieq(cmd, 58) then let
            val ntabs = tabs_len(ts_inter)
            val () = if igt(ntabs, 1) then let
                val prev_i = isub(s.active, 1)
                val cur_i = if ilt(prev_i, 0) then isub(ntabs, 1) else prev_i
                val () = s.active := cur_i
                val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
              in
              end else ()
          in
          end else ()
        val ts2 = key_dispatch(ts_inter, idx, cmd, s.vault, s.clip, s.scratch, p, s.paste, ev)
        val ph = s.tabs
        val () = s.tabs := ts2
        val () = tabs_free(ph)
        val () = if ieq(cmd, 15) then let
            val () = s.treedirty := 1
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else ()
        val _f = font_line_h(f)
      in
        fold@(a)
      end
fun on_down(a: !App, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) =>
      if ieq(s.vault_select, 1) then let
        val x = ev_x(ev)
        val y = ev_y(ev)
        val mw = 520
        val mh = 360
        val mx = idiv(isub(w, mw), 2)
        val my = idiv(isub(h, mh), 2)

        // Existing vaults list click
        val in_list_y = if ige(y, iadd(my, 74)) andalso ilt(y, iadd(my, iadd(74, imul(imin(s.vcnt, 6), 28)))) then 1 else 0
        val in_list_x = if ige(x, iadd(mx, 16)) andalso ilt(x, isub(iadd(mx, mw), 16)) then 1 else 0
        val () = if ieq(in_list_x, 1) andalso ieq(in_list_y, 1) then let
          val vi = idiv(isub(y, iadd(my, 74)), 28)
          val () = if ige(vi, 0) andalso ilt(vi, s.vcnt) then let
            val poff = buf_get32(s.vmeta, imul(vi, 4))
            val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
            var pbuf = buf_make(256)
            val () = bcat(pbuf, s.vpaths, poff, iadd(poff, plen))
            val target = cstr(pbuf)
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
            val () = bclear(s.vault)
            val () = bstr(s.vault, target)
            val () = conf_set_active_vault(target)
            val old_t = s.tabs
            val () = s.tabs := TNil()
            var n_fpx: int = 18
            var n_vm: int = 0
            var n_sp: int = 0
            var n_act: int = 0
            val new_t = switch_vault_tabs(old_t, target, s.font_path, n_fpx, n_vm, n_sp, n_act)
            val ph = s.tabs
            val () = s.tabs := new_t
            val () = tabs_free(ph)
            val () = s.fontpx := n_fpx
            val () = s.viewmode := n_vm
            val () = s.split := n_sp
            val () = s.active := n_act
            val () = s.righti := 0
            val () = s.treedirty := 1
            val () = bclear(s.promptb)
            val () = buf_free(pbuf)
            val () = s.vault_select := 0
          in
            ()
          end else ()
        in
          ()
        end else ()

        // Click on "[ Ac / Olustur ]" button
        val on_open_btn = if ige(x, iadd(mx, 16)) andalso ilt(x, iadd(mx, 156)) andalso ige(y, iadd(my, 312)) andalso ilt(y, iadd(my, 342)) then 1 else 0
        val () = if ieq(on_open_btn, 1) andalso igt(buf_len(s.promptb), 0) then let
          val target = cstr(s.promptb)
          val _mk = fs_mkdir(target)
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          val () = bclear(s.vault)
          val () = bstr(s.vault, target)
          val () = conf_set_active_vault(target)
          val old_t = s.tabs
          val () = s.tabs := TNil()
          var n_fpx: int = 18
          var n_vm: int = 0
          var n_sp: int = 0
          var n_act: int = 0
          val new_t = switch_vault_tabs(old_t, target, s.font_path, n_fpx, n_vm, n_sp, n_act)
          val ph = s.tabs
          val () = s.tabs := new_t
          val () = tabs_free(ph)
          val () = s.fontpx := n_fpx
          val () = s.viewmode := n_vm
          val () = s.split := n_sp
          val () = s.active := n_act
          val () = s.righti := 0
          val () = s.treedirty := 1
          val () = bclear(s.promptb)
          val () = s.vault_select := 0
        in
          ()
        end else ()

        // Click on "[ Iptal ]" button
        val on_cancel_btn = if ige(x, isub(iadd(mx, mw), 116)) andalso ilt(x, isub(iadd(mx, mw), 16)) andalso ige(y, iadd(my, 312)) andalso ilt(y, iadd(my, 342)) then 1 else 0
        val () = if ieq(on_cancel_btn, 1) andalso igt(buf_len(s.vault), 0) then let
          val () = s.vault_select := 0
        in
          ()
        end else ()
      in
        fold@(a)
      end else let
        val x = ev_x(ev)
        val y = ev_y(ev)
        val () = s.downx := x
        val () = s.downy := y
        val sidew = if igt(s.side, 0) then 280 else 0
        val button = ev_button(ev)
        val _h = h
        val skip = if igt(s.menu, 0) then 1 else 0
        val onbar = if ilt(y, 36) then 1 else 0
        val onside = if ieq(skip, 0) andalso igt(sidew, 0) andalso ilt(x, sidew) andalso ieq(onbar, 0) then 1 else 0
        val item = idiv(isub(y, s.menuy), 22)
        val inside = if ige(x, s.menux) andalso ilt(x, iadd(s.menux, 230)) andalso ige(y, s.menuy) then 1 else 0
        val () = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 3) andalso ieq(item, 0) then s.prompt := 1 else ()
        val () = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 3) andalso ieq(item, 1) then s.prompt := 2 else ()
        val () = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 3) andalso ieq(item, 2) then s.prompt := 3 else ()
        val () = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 3) andalso ieq(item, 3) andalso ige(s.sel, 0) then let
            var cur = buf_make(8)
            val () = row_path(s.tree, s.tmeta, s.sel, cur)
            val () = do_delete(cur)
            val () = s.treedirty := 1
          in
            buf_free(cur)
          end else ()
        val () = font_set_px(f, s.fontpx)
        val top_w = 96
        val x1 = 8
        val x2 = iadd(x1, iadd(top_w, 6))
        val x3 = iadd(x2, iadd(top_w, 6))
        val tab_sep_x = iadd(x3, iadd(top_w, 14))
        val tab_x0 = iadd(tab_sep_x, 16)

        val btxt = if ieq(s.viewmode, 0) then "Düzenle" else "Okuma"
        val bw = 96
        val bx = isub(w, iadd(bw, 10))

        val onbtn = if ieq(onbar, 1) andalso ieq(skip, 0) andalso ige(x, bx) andalso ilt(x, iadd(bx, bw)) then 1 else 0
        val () = if ieq(onbtn, 1) then let
          val () = s.viewmode := iif(ieq(s.viewmode, 0), 1, 0)
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
        in
          ()
        end else ()

        val on_g = if ieq(onbar, 1) andalso ieq(skip, 0) andalso ige(x, x1) andalso ilt(x, iadd(x1, top_w)) then 1 else 0
        val () = if ieq(on_g, 1) then let
            val () = s.side := iif(ieq(s.side, 1), 0, 1)
          in
            s.qfocus := 0
          end else ()

        val on_s = if ieq(onbar, 1) andalso ieq(skip, 0) andalso ige(x, x2) andalso ilt(x, iadd(x2, top_w)) then 1 else 0
        val () = if ieq(on_s, 1) then let
            val () = s.side := iif(ieq(s.side, 2), 0, 2)
          in
            s.qfocus := iif(ieq(s.side, 2), 1, 0)
          end else ()

        val on_cfg = if ieq(onbar, 1) andalso ieq(skip, 0) andalso ige(x, x3) andalso ilt(x, iadd(x3, top_w)) then 1 else 0
        val () = if ieq(on_cfg, 1) then let
            val () = s.side := iif(ieq(s.side, 3), 0, 3)
          in
            s.qfocus := 0
          end else ()

        val ts0 = s.tabs
        val () = s.tabs := TNil()
        val idx = if ieq(s.focus, 0) then s.active else s.righti

        var ti: int = ~1
        var close: int = 0
        val () = if ieq(onbar, 1) andalso ieq(skip, 0) andalso ige(x, tab_x0) andalso ilt(x, bx) then
          tab_hit_test(f, r, ts0, tab_x0, x, ti, close)
        else ()

        val ntabs = tabs_len(ts0)
        val pick = if ieq(onbar, 1) andalso ieq(skip, 0) andalso ige(ti, 0) andalso ilt(ti, ntabs) andalso ieq(close, 0) then 1 else 0
        val () = if ieq(pick, 1) then let
            val () = s.drag := 0
            val () = s.dragi := ti
            val () = s.downx := x
            val () = s.downy := y
            val () = s.active := ti
            val () = s.focus := 0
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else ()
        val cut = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 1) andalso ieq(item, 0) then 1 else 0
        val copy = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 1) andalso ieq(item, 1) then 1 else 0
        val paste = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 1) andalso ieq(item, 2) then 1 else 0
        val clear = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 1) andalso ieq(item, 3) then 1 else 0
        val imgcopy = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 2) andalso ieq(item, 0) then 1 else 0
        val imgrev = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 2) andalso ieq(item, 1) then 1 else 0
        val imgdel = if ieq(skip, 1) andalso ieq(inside, 1) andalso ieq(s.menu, 2) andalso ieq(item, 2) then 1 else 0
        val () = copy_if(ts0, idx, s.clip, iif(ieq(cut, 1) orelse ieq(copy, 1), 1, 0))
        val () = clip_image(ts0, idx, s.hiti, s.vault, s.clip, imgcopy)
        val own = if ieq(cut, 1) orelse ieq(copy, 1) orelse ieq(imgcopy, 1) then 1 else 0
        val () = if ieq(own, 1) then plat_own(p, 0) else ()
        val () = if ieq(own, 1) then plat_own(p, 1) else ()
        val () = if ieq(paste, 1) then let
            val () = s.paste := 1
          in
            plat_paste(p, 0)
          end else ()
        val () = if ieq(imgrev, 1) then s.side := 1 else ()
        val ts1 = cmd_if(ts0, idx, 10, cut)
        val ts2 = tab_keep_one(drop_if(ts1, ti, close), close)
        val () = if ieq(close, 1) then let
            val () = s.active := 0
            val () = if ieq(s.split, 1) andalso ilt(tabs_len(ts2), 2) then s.split := 0 else ()
            val () = s.righti := 0
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else ()
        val row = idiv(isub(y, 72), 18)
        val valid_row = if ige(y, 72) andalso ige(row, 0) andalso ilt(row, s.tn) then 1 else 0
        val openf = if ieq(onside, 1) andalso ieq(s.side, 1) andalso ieq(valid_row, 1) andalso ieq(buf_get32(s.tmeta, iadd(imul(row, 4), 1)), 0) then 1 else 0
        val () = if ieq(onside, 1) andalso ieq(s.side, 1) then let
            val () = s.sel := (if ieq(valid_row, 1) then row else ~1)
            val () = s.drag := (if ieq(valid_row, 1) then 2 else 0)
            val () = s.dragi := (if ieq(valid_row, 1) then row else ~1)
          in
            ()
          end else ()
        val srow = if ige(y, 100) then idiv(isub(y, 100), 18) else ~1
        val open_hit_flag = if ieq(onside, 1) andalso ieq(s.side, 2) andalso ige(srow, 0) andalso ilt(srow, s.hn) then 1 else 0
        val ts2_hit = open_hit(ts2, s.hmeta, s.hits, srow, open_hit_flag)
        val ts3 = open_row(ts2_hit, s.tree, s.tmeta, row, openf)
        val () = if ieq(openf, 1) orelse ieq(open_hit_flag, 1) then let
          val () = s.active := 0
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
        in
          ()
        end else ()
        val () = if ieq(onside, 1) andalso ieq(s.side, 2) andalso ieq(open_hit_flag, 0) then s.qfocus := 1 else ()

        // Kasayi Degistir click:
        val on_kasa_btn = if ieq(onside, 1) andalso ieq(s.side, 3) andalso ige(x, 12) andalso ilt(x, 162) andalso ige(y, 122) andalso ilt(y, 144) then 1 else 0
        val () = if ieq(on_kasa_btn, 1) then let
          val () = conf_list_vaults(s.vpaths, s.vnames, s.vmeta, s.vcnt)
          val () = s.vault_select := 1
        in
          ()
        end else ()

        // Font size click:
        val nxtpx = if ieq(s.fontpx, 16) then 18 else if ieq(s.fontpx, 18) then 20 else 16
        val () = if ieq(onside, 1) andalso ieq(s.side, 3) andalso igt(y, 148) andalso ilt(y, 175) then let
          val () = s.fontpx := nxtpx
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
        in
          ()
        end else ()

        // Dynamic font list click:
        val max_fi = imin(s.fcnt, 12)
        val on_font_list = if ieq(onside, 1) andalso ieq(s.side, 3) andalso ige(y, 205) andalso ilt(y, iadd(210, imul(max_fi, 22))) then 1 else 0
        val () = if ieq(on_font_list, 1) then let
          val sel_fi = idiv(isub(y, 205), 22)
          val () = if ige(sel_fi, 0) andalso ilt(sel_fi, s.fcnt) then let
            val poff = buf_get32(s.fmeta, imul(sel_fi, 4))
            val plen = buf_get32(s.fmeta, iadd(imul(sel_fi, 4), 1))
            val () = bclear(s.font_path)
            val () = bcat(s.font_path, s.fpaths, poff, iadd(poff, plen))
            val _ok = font_use_file(f, cstr(s.font_path))
            val () = font_set_px(f, s.fontpx)
            val () = s.font_idx := 1
            val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
          in
            ()
          end else ()
        in
          ()
        end else ()

        val pw0 = isub(w, sidew)
        val half = if ieq(s.split, 1) then idiv(pw0, 2) else pw0
        val editor = if ieq(skip, 0) andalso ieq(onbar, 0) andalso ieq(onside, 0) andalso ieq(button, 1) then 1 else 0
        val foc = if ieq(editor, 1) andalso ieq(s.split, 1) andalso ige(x, iadd(sidew, half)) then 1 else 0
        val () = if ieq(editor, 1) then s.focus := foc else ()
        val ox = if ieq(s.focus, 1) then iadd(sidew, half) else sidew
        val idx2 = if ieq(s.focus, 0) then s.active else s.righti
        val keep = iif(iand(ev_mods(ev), mod_shift()) <> 0, 1, 0)
        val () = font_set_px(f, s.fontpx)
        val ts4 = click_go(f, r, ts3, idx2, x, y, ox, half, font_line_h(f), s.scratch, keep, s.hitk, s.hiti, editor)
        val colx_hit = column_x(ox, half)
        val on_arrow = if ieq(editor, 1) andalso ige(x, isub(colx_hit, 24)) andalso ilt(x, colx_hit) andalso ige(s.hiti, 0) then 1 else 0
        val on_task = if ieq(editor, 1) andalso ieq(s.hitk, 19) andalso ige(x, colx_hit) andalso ilt(x, iadd(colx_hit, 36)) andalso ige(s.hiti, 0) then 1 else 0
        val ts4_a = toggle_go(ts4, idx2, s.hiti, on_arrow)
        val ts4_b = toggle_task_go(ts4_a, idx2, s.hiti, on_task)
        val gowiki = if ieq(editor, 1) andalso ieq(ctrl_on(ev), 1) then 1 else 0
        val ts5 = wiki_go(ts4_b, idx2, s.vault, gowiki)
        val ts6 = del_go(ts5, idx, s.hiti, imgdel)
        val ts7 = clear_go(ts6, idx, clear)
        val () = if ieq(editor, 1) andalso ieq(ctrl_on(ev), 1) then let
          val () = s.active := 0
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
        in
          ()
        end else ()
        val () = if ieq(editor, 1) then s.qfocus := 0 else ()
        val () = if ieq(button, 3) andalso ieq(skip, 0) then let
            val () = s.menux := x
            val () = s.menuy := y
          in
            if ieq(onside, 1) then let
              val () = s.menu := 3
              val row = idiv(isub(y, 72), 18)
              val valid_row = if ige(y, 72) andalso ige(row, 0) andalso ilt(row, s.tn) then 1 else 0
            in
              s.sel := (if ieq(valid_row, 1) then row else ~1)
            end else s.menu := iif(ieq(s.hitk, 26), 2, 1)
          end else ()
        val ph = s.tabs
        val () = s.tabs := ts7
        val () = tabs_free(ph)
        val () = if ieq(skip, 1) then s.menu := 0 else ()
      in
        fold@(a)
      end

fun on_motion(a: !App, ev: &event): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val () = if ige(s.downx, 0) andalso ige(s.dragi, 0) andalso ilt(s.downy, 36) then
        if igt(iabs(isub(x, s.downx)), 8) then s.drag := 1 else ()
      else ()
    in
      fold@(a)
    end

fun on_up(a: !App, f: !Font, r: !Rend, ev: &event, w: int): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val y = ev_y(ev)
      val () = if ieq(s.drag, 1) andalso igt(y, 36) then let
        val sidew = if igt(s.side, 0) then 280 else 0
        val mid = iadd(sidew, idiv(isub(w, sidew), 2))
      in
        if ige(x, mid) then let
          val () = s.split := 1
          val () = s.righti := s.dragi
          val () = s.focus := 1
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
        in
          ()
        end else ()
      end else if ieq(s.drag, 1) andalso ilt(y, 36) andalso ige(s.dragi, 0) then let
        val w1 = top_btn_w(f, r, "Gezgin", 72)
        val w2 = top_btn_w(f, r, "Arama", 68)
        val w3 = top_btn_w(f, r, "Ayarlar", 76)
        val tab_x0 = iadd(6, iadd(w1, iadd(6, iadd(w2, iadd(6, iadd(w3, 14))))))
        var target_ti: int = ~1
        var dummy_close: int = 0
        val () = tab_hit_test(f, r, s.tabs, tab_x0, x, target_ti, dummy_close)
        val ntabs = tabs_len(s.tabs)
        val ti = if ige(target_ti, 0) then target_ti else if ige(x, tab_x0) then isub(ntabs, 1) else 0
        val () = if ige(ti, 0) andalso ilt(ti, ntabs) andalso ine(ti, s.dragi) then let
          val+ ~PAIR(one, rest) = tabs_detach(s.tabs, s.dragi)
          val () = s.tabs := tabs_insert(rest, ti, one)
          val () = s.active := ti
          val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.tabs)
        in
          ()
        end else ()
      in
        ()
      end else if ieq(s.drag, 2) andalso ige(s.sel, 0) then let
        val row = idiv(isub(y, 72), 18)
        val () = if ige(row, 0) andalso ilt(row, s.tn) andalso ine(row, s.dragi) andalso ieq(buf_get32(s.tmeta, iadd(imul(row, 4), 1)), 1) then let
          var srcp = buf_make(8)
          var dstp = buf_make(8)
          var name = buf_make(8)
          var final = buf_make(8)
          val () = row_path(s.tree, s.tmeta, s.dragi, srcp)
          val () = row_path(s.tree, s.tmeta, row, dstp)
          val () = base_name(srcp, name)
          val () = child_path(dstp, name, final)
          val _r = fs_rename(cstr(srcp), cstr(final))
          val () = s.treedirty := 1
          val () = buf_free(srcp)
          val () = buf_free(dstp)
          val () = buf_free(name)
        in
          buf_free(final)
        end else ()
      in
        ()
      end else ()
      val () = s.drag := 0
      val () = s.dragi := ~1
      val () = s.downx := ~1
      val () = s.downy := ~1
      val n = tabs_len(s.tabs)
      val () = if ige(s.active, n) then s.active := imax(0, isub(n, 1)) else ()
      val () = if ilt(s.active, 0) then s.active := 0 else ()
    in
      fold@(a)
    end

fun on_wheel(a: !App, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val dv = if ieq(ev_button(ev), 4) then ~48 else 48
      val idx = if ieq(s.focus, 0) then s.active else s.righti
      val ts = s.tabs
      val () = s.tabs := TNil()
      val ph = s.tabs
      val () = s.tabs := tabs_scroll(ts, idx, dv, 100000)
      val () = tabs_free(ph)
      val _w = w
      val _h = h
    in
      fold@(a)
    end

fun on_sel(a: !App, p: !Plat, ev: &event): void =
  case+ a of
  | @APP(s) => let
      val k = ev_kind(ev)
      val () = if k = EV_SEL_REQ then plat_reply(p, ev, buf_ptr(s.clip), buf_len(s.clip))
        else if k = EV_SEL_NOTIFY andalso ieq(s.paste, 1) then let
          val n = plat_read(p, ev, buf_ptr(s.scratch), buf_cap(s.scratch))
          val idx = if ieq(s.focus, 0) then s.active else s.righti
          val ts = s.tabs
          val () = s.tabs := TNil()
          val sp = buf_ptr(s.scratch)
          val ph = s.tabs
          val ts2 = tabs_ins(ts, idx, sp, n)
          val () = tabs_sync_vfs(ts2, idx)
          val () = s.tabs := ts2
          val () = tabs_free(ph)
          val () = s.paste := 0
        in
          ()
        end else ()
    in
      fold@(a)
    end

implement app_event(a, p, f, r, ev, w, h) = let
  val k = ev_kind(ev)
in
  if k = EV_KEY then on_key(a, p, f, ev)
  else if k = EV_DOWN then on_down(a, p, f, r, ev, w, h)
  else if k = EV_UP then on_up(a, f, r, ev, w)
  else if k = EV_MOTION then on_motion(a, ev)
  else if k = EV_WHEEL then on_wheel(a, ev, w, h)
  else if k = EV_SEL_REQ orelse k = EV_SEL_NOTIFY then on_sel(a, p, ev)
  else ()
end
fun find_img(doc: !Doc, i: int): int =
  if ige(i, doc_nnodes(doc)) then ~1
  else if ieq(doc_get(doc, i, 0), 26) then i
  else find_img(doc, iadd(i, 1))

implement app_selftest(r) = let
  var q = buf_make(16)
  val () = bstr(q, "anthracite")
  var d1 = buf_make(32)
  val () = bstr(d1, "/tmp/anth-s")
  val _mk = fs_mkdir(cstr(d1))
  var f1 = buf_make(40)
  var f2 = buf_make(40)
  val () = bstr(f1, "/tmp/anth-s/a.md")
  val () = bstr(f2, "/tmp/anth-s/b.md")
  var body = buf_make(32)
  val () = bstr(body, "anthracite bir\n")
  val w1 = write_text(f1, body)
  val () = bclear(body)
  val () = bstr(body, "anthracite iki\n")
  val w2 = write_text(f2, body)
  var hits = buf_make(64)
  var hmeta = buf_make(64)
  var hn: int = 0
  val () = refresh_search(d1, q, hits, hmeta, hn)
  val search_ok = if ige(hn, 2) andalso ieq(w1, 1) andalso ieq(w2, 1) then 1 else 0
  val doc = doc_open()
  val () = doc_insert(doc, c_str_ptr("hello\n\n![](/tmp/anth-t.png)\n\nworld\n"), c_strlen("hello\n\n![](/tmp/anth-t.png)\n\nworld\n"))
  var cache = CNil()
  var vault = buf_make(8)
  val () = bstr(vault, "/tmp")
  var scratch = buf_make(256)
  val height = prep_doc(doc, cache, r, vault, 18, 720)
  val ii = find_img(doc, 0)
  val iy = if ige(ii, 0) then doc_get(doc, ii, 13) else ~1
  val ih = if ige(ii, 0) then doc_get(doc, ii, 5) else 0
  val flow_ok = if ige(ii, 0) andalso igt(ih, 8) andalso ige(height, iadd(iy, ih)) then 1 else 0
  val docA = doc_open()
  val () = doc_insert(docA, c_str_ptr("[[b]]\n"), 6)
  val () = doc_set_caret(docA, 2, 0)
  var ta = buf_make(4)
  var pa = buf_make(4)
  val tsA = tabs_add(TNil(), docA, pa, ta)
  val docB = doc_open()
  var tb = buf_make(4)
  var pb = buf_make(4)
  val tsB = tabs_add(tsA, docB, pb, tb)
  val n2 = tabs_len(tsB)
  val tsC = tabs_drop(tsB, 1)
  val n1 = tabs_len(tsC)
  val tsD = wiki_open(tsC, 0, d1, 0)
  val nw = tabs_len(tsD)
  val () = tabs_free(tsD)
  var sub = buf_make(40)
  val () = bstr(sub, "/tmp/anth-s/sub")
  val _mk2 = fs_mkdir(cstr(sub))
  var src = buf_make(48)
  val () = bstr(src, "/tmp/anth-s/move.md")
  var one = buf_make(4)
  val () = bstr(one, "x\n")
  val _w3 = write_text(src, one)
  var dstp = buf_make(48)
  val () = bstr(dstp, "/tmp/anth-s/sub/move.md")
  val mv = fs_rename(cstr(src), cstr(dstp))
  val moved = fs_exists(cstr(dstp))
  val _ul = fs_unlink(cstr(dstp))
  val gone = fs_exists(cstr(dstp))
  val _rm = fs_rmdir(cstr(sub))
  val chrome_ok = if ieq(n2, 2) andalso ieq(n1, 1) andalso ieq(nw, 2) then 1 else 0
  val files_ok = if ieq(mv, 0) andalso ieq(moved, 1) andalso ieq(gone, 0) then 1 else 0
  val () = buf_free(sub)
  val () = buf_free(src)
  val () = buf_free(one)
  val () = buf_free(dstp)
  val fnt = font_open()
  val () = rend_begin(r, 800, 600)
  var py: int = 0
  var pa: int = 0
  val () = draw_nodes(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, 0)
  val () = draw_nodes(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, 1)
  val _h_view = draw_doc(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 1)

  // Validate all ported RAD UI widgets
  val () = ui_draw_border(r, 10, 10, 100, 50, 1, col_line())
  val () = ui_draw_shadow(r, 10, 10, 100, 50, 4)
  val () = ui_draw_icon(fnt, r, UI_ICON_FOLDER, 12, 12, 12, col_accent())
  val () = ui_divider(r, 0, 0, 100, 0)
  val _lw = ui_label(fnt, r, 20, 20, "test", col_text())
  val _lm = ui_label_multiline(fnt, r, 20, 30, 80, "multi line label", col_text(), 14)
  val _bw = ui_badge(fnt, r, 20, 50, "badge", col_bar(), col_accent())
  val () = ui_button(fnt, r, 20, 70, 80, 24, "button", 0, 0)
  val () = ui_hover_label(fnt, r, 20, 100, 80, 20, "hover", 0)
  val () = ui_expander(fnt, r, 20, 125, 1, 0)
  val () = ui_sort_header(fnt, r, 20, 140, 80, 20, "col", 1, 1, 0)
  val () = ui_toggle_switch(r, 20, 165, 36, 18, 1)
  val () = ui_slider(r, 20, 190, 80, 16, 50, 0, 0)
  val () = ui_scroll_bar(r, 20, 210, 8, 100, 1, 500, 100, 50, 0, 0)
  val () = ui_line_edit_draw(fnt, r, 20, 320, 120, 24, scratch, 0, 0, 1, "test")
  val () = ui_pane_begin(r, 150, 10, 200, 150, col_bg())
  val () = ui_pane_draw_header(fnt, r, 150, 10, 200, "Pane Header", 1)
  val () = ui_color_picker(r, 150, 170, 100, 24, 255, 128, 64)
  val () = rd_menu_bar_button(fnt, r, 150, 200, 60, 24, "Menu", 1, 0)
  val () = rd_icon_button(fnt, r, UI_ICON_SETTINGS, "Options", 150, 230, 80, 24, 0, 0)
  val () = rd_cell(fnt, r, 150, 260, 160, 20, 0, 1, 1, UI_ICON_FOLDER, "Doc", "5 kb", 1, 0)
  val () = rd_loading_overlay(fnt, r, 800, 600, 50, "Loading", "Please wait...")
  val () = rd_code_slice(fnt, r, 150, 290, 200, 20, 42, "val x = 1", 1, 1, 0)

  val () = font_free(fnt)
  val () = doc_free(doc)
  val () = cache_free(cache)
  val () = buf_free(q)
  val () = buf_free(d1)
  val () = buf_free(f1)
  val () = buf_free(f2)
  val () = buf_free(body)
  val () = buf_free(hits)
  val () = buf_free(hmeta)
  val () = buf_free(vault)
  val () = buf_free(scratch)
  val () = print("ui search=")
  val () = print_int(search_ok)
  val () = print(" flow=")
  val () = print_int(flow_ok)
  val () = print(" h=")
  val () = print_int(ih)
  val () = print(" chrome=")
  val () = print_int(chrome_ok)
  val () = print(" files=")
  val () = print_int(files_ok)
  val () = print_newline()
in
  iif(ieq(search_ok, 1) andalso ieq(flow_ok, 1) andalso ieq(chrome_ok, 1) andalso ieq(files_ok, 1), 1, 0)
end
