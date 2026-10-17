fun has_esc_byte(b: !Buf, n: int, i: int): bool =
  if ige(i, n) then false
  else has_esc_loop(b, airlock_span(i, n), i)

fun compact_loop {rem:nat} .<rem>. (b: !Buf, n: int, rem: int(rem), r: int, w: int): int =
  if rem > 0 then let
    val byte = buf_get(b, r)
    val keep = (ige(byte, CHAR_SPACE) andalso ine(byte, CHAR_DEL)) orelse ieq(byte, CHAR_TAB) orelse ieq(byte, CHAR_LF)
  in
    if keep then let
      val () = buf_set(b, w, byte)
    in
      compact_loop(b, n, rem - 1, iadd(r, 1), iadd(w, 1))
    end else compact_loop(b, n, rem - 1, iadd(r, 1), w)
  end
  else w

fun compact_bytes(b: !Buf, n: int, r: int, w: int): int =
  if ige(r, n) then w
  else compact_loop(b, n, airlock_span(r, n), r, w)

implement filter_text(b, n) =
  if has_esc_byte(b, n, 0) then 0
  else compact_bytes(b, n, 0, 0)

implement scan_skip(name) =
  ieq(buf_len(name), 0) orelse ieq(buf_get(name, 0), CHAR_DOT)

implement meta_dir(meta, row) =
  dir_mark_of(buf_get32(meta, iadd(imul(row, 4), 1)))

implement meta_depth(meta, row) =
  buf_get32(meta, imul(row, 4))

implement meta_text_off(meta, row) =
  buf_get32(meta, iadd(imul(row, 4), 2))

implement meta_text_len(meta, row) =
  buf_get32(meta, iadd(imul(row, 4), 3))

implement path_is_dir(path) = ieq(fs_isdir(path), 1)

implement child_kind(child, skip, isdir) =
  if is_on(skip) then DirNo
  else if is_dir_mark(isdir, DirYes) then DirYes
  else if is_dir_mark(isdir, DirNo) then DirNo
  else dir_mark_of(fs_isdir(buffer_c_string(child)))

implement is_side_none(x) = case+ x of
  | SideNone() => true
  | SideFiles() => false
  | SideSearch() => false
  | SideConfig() => false

implement is_side_files(x) = case+ x of
  | SideFiles() => true
  | SideNone() => false
  | SideSearch() => false
  | SideConfig() => false

implement is_side_search(x) = case+ x of
  | SideSearch() => true
  | SideNone() => false
  | SideFiles() => false
  | SideConfig() => false

implement is_side_config(x) = case+ x of
  | SideConfig() => true
  | SideNone() => false
  | SideFiles() => false
  | SideSearch() => false

implement is_menu_none(x) = case+ x of
  | MenuNone() => true
  | MenuText() => false
  | MenuImage() => false
  | MenuFileTree() => false

implement is_menu_text(x) = case+ x of
  | MenuText() => true
  | MenuNone() => false
  | MenuImage() => false
  | MenuFileTree() => false

implement is_menu_image(x) = case+ x of
  | MenuImage() => true
  | MenuNone() => false
  | MenuText() => false
  | MenuFileTree() => false

implement is_menu_filetree(x) = case+ x of
  | MenuFileTree() => true
  | MenuNone() => false
  | MenuText() => false
  | MenuImage() => false

implement is_prompt_none(x) = case+ x of
  | PromptNone() => true
  | PromptNewFile() => false
  | PromptNewFolder() => false
  | PromptRename() => false

implement is_prompt_newfile(x) = case+ x of
  | PromptNewFile() => true
  | PromptNone() => false
  | PromptNewFolder() => false
  | PromptRename() => false

implement is_prompt_newfolder(x) = case+ x of
  | PromptNewFolder() => true
  | PromptNone() => false
  | PromptNewFile() => false
  | PromptRename() => false

implement is_prompt_rename(x) = case+ x of
  | PromptRename() => true
  | PromptNone() => false
  | PromptNewFile() => false
  | PromptNewFolder() => false

implement is_view_edit(x) = case+ x of
  | ViewEdit() => true
  | ViewRead() => false

implement is_view_read(x) = case+ x of
  | ViewRead() => true
  | ViewEdit() => false

implement is_edit_none(x) = case+ x of
  | EditNone() => true
  | EditChanged() => false
  | EditSubmit() => false
  | EditCancel() => false

implement is_edit_changed(x) = case+ x of
  | EditChanged() => true
  | EditNone() => false
  | EditSubmit() => false
  | EditCancel() => false

implement is_edit_submit(x) = case+ x of
  | EditSubmit() => true
  | EditNone() => false
  | EditChanged() => false
  | EditCancel() => false

implement is_edit_cancel(x) = case+ x of
  | EditCancel() => true
  | EditNone() => false
  | EditChanged() => false
  | EditSubmit() => false

implement is_drag_none(x) = case+ x of
  | DragNone() => true
  | DragTab() => false
  | DragFile() => false
  | DragSplit() => false
  | DragEditor() => false

implement is_drag_tab(x) = case+ x of
  | DragTab() => true
  | DragNone() => false
  | DragFile() => false
  | DragSplit() => false
  | DragEditor() => false

implement is_drag_file(x) = case+ x of
  | DragFile() => true
  | DragNone() => false
  | DragTab() => false
  | DragSplit() => false
  | DragEditor() => false

implement is_drag_split(x) = case+ x of
  | DragSplit() => true
  | DragNone() => false
  | DragTab() => false
  | DragFile() => false
  | DragEditor() => false

implement is_drag_editor(x) = case+ x of
  | DragEditor() => true
  | DragNone() => false
  | DragTab() => false
  | DragFile() => false
  | DragSplit() => false

implement view_mode_code(v) = case+ v of
  | ViewEdit() => 0
  | ViewRead() => 1

implement view_mode_of_code(n) = if ieq(n, 1) then ViewRead else ViewEdit
