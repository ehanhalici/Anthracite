#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_platform/x11.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "ui_workspace/commands/ui_keymap.sats"
staload "ui_workspace/commands/ui_menu.sats"

fun anth_ior(a: int, b: int): int =
  isub(iadd(a, b), anth_iand(a, b))

fun km_word(km: !Buf, idx: int, fld: int): int =
  buf_get32(km, iadd(imul(idx, KEYMAP_ENTRY_WORDS), fld))

fun km_set_word(km: &Buf >> _, idx: int, fld: int, v: int): void =
  buf_set32(km, iadd(imul(idx, KEYMAP_ENTRY_WORDS), fld), v)

implement keymap_count(km) = idiv(buf_len(km), KEYMAP_ENTRY_BYTES)
implement keymap_clear(km) = buf_set_len(km, 0)

fun km_same_seq(km: !Buf, idx: int, m1: int, k1: int, m2: int, k2: int): bool =
  ieq(km_word(km, idx, KEYMAP_FLD_MOD1), m1)
  andalso ieq(km_word(km, idx, KEYMAP_FLD_KEY1), k1)
  andalso ieq(km_word(km, idx, KEYMAP_FLD_MOD2), m2)
  andalso ieq(km_word(km, idx, KEYMAP_FLD_KEY2), k2)

fun km_find_m {rem:nat} .<rem>. (
  km: !Buf, i: int, m1: int, k1: int, m2: int, k2: int, rem: int(rem)
): int =
  if rem = 0 then ~1
  else if km_same_seq(km, i, m1, k1, m2, k2) then i
  else km_find_m(km, iadd(i, 1), m1, k1, m2, k2, rem - 1)

fun km_find(km: !Buf, m1: int, k1: int, m2: int, k2: int): int = let
  val n = keymap_count(km)
in
  if ile(n, 0) then ~1 else km_find_m(km, 0, m1, k1, m2, k2, airlock_nat(imax(0, n)))
end

fun km_has_prefix_m {rem:nat} .<rem>. (km: !Buf, i: int, m1: int, k1: int, rem: int(rem)): bool =
  if rem = 0 then false
  else let
    val em1 = km_word(km, i, KEYMAP_FLD_MOD1)
    val ek1 = km_word(km, i, KEYMAP_FLD_KEY1)
    val ek2 = km_word(km, i, KEYMAP_FLD_KEY2)
    val ecmd = km_word(km, i, KEYMAP_FLD_CMD)
  in
    if ieq(em1, m1) andalso ieq(ek1, k1) andalso igt(ek2, 0) andalso igt(ecmd, 0) then true
    else km_has_prefix_m(km, iadd(i, 1), m1, k1, rem - 1)
  end

fun km_has_prefix(km: !Buf, m1: int, k1: int): bool = let
  val n = keymap_count(km)
in
  if ile(n, 0) then false else km_has_prefix_m(km, 0, m1, k1, airlock_nat(imax(0, n)))
end

fun km_clear_single_conflict(km: &Buf >> _, m1: int, k1: int): void = let
  val idx = km_find(km, m1, k1, 0, 0)
in
  if ige(idx, 0) then km_set_word(km, idx, KEYMAP_FLD_CMD, 0) else ()
end

fun km_clear_prefix_conflicts_m {rem:nat} .<rem>. (
  km: &Buf >> _, i: int, m1: int, k1: int, rem: int(rem)
): void =
  if rem = 0 then ()
  else let
    val em1 = km_word(km, i, KEYMAP_FLD_MOD1)
    val ek1 = km_word(km, i, KEYMAP_FLD_KEY1)
    val ek2 = km_word(km, i, KEYMAP_FLD_KEY2)
    val () = if ieq(em1, m1) andalso ieq(ek1, k1) andalso igt(ek2, 0) then
      km_set_word(km, i, KEYMAP_FLD_CMD, 0) else ()
  in
    km_clear_prefix_conflicts_m(km, iadd(i, 1), m1, k1, rem - 1)
  end

fun km_write_slot(km: &Buf >> _, idx: int, m1: int, k1: int, m2: int, k2: int, code: int): void = let
  val () = km_set_word(km, idx, KEYMAP_FLD_MOD1, m1)
  val () = km_set_word(km, idx, KEYMAP_FLD_KEY1, k1)
  val () = km_set_word(km, idx, KEYMAP_FLD_MOD2, m2)
  val () = km_set_word(km, idx, KEYMAP_FLD_KEY2, k2)
  val () = km_set_word(km, idx, KEYMAP_FLD_CMD, code)
in
  km_set_word(km, idx, KEYMAP_FLD_ARG, 0)
end

implement keymap_bind(km, m1, k1, m2, k2, cmd) = let
  val cnt = keymap_count(km)
  val () = if igt(k2, 0) then km_clear_single_conflict(km, m1, k1)
           else km_clear_prefix_conflicts_m(km, 0, m1, k1, airlock_nat(imax(0, cnt)))
  val existing = km_find(km, m1, k1, m2, k2)
  val code = cmd_code(cmd)
in
  if ige(existing, 0) then km_write_slot(km, existing, m1, k1, m2, k2, code)
  else let
    val n = keymap_count(km)
    val need = imul(iadd(n, 1), KEYMAP_ENTRY_BYTES)
    val () = buf_ensure(km, need)
    val () = buf_set_len(km, need)
  in
    km_write_slot(km, n, m1, k1, m2, k2, code)
  end
end

implement keymap_unbind(km, m1, k1, m2, k2) = let
  val idx = km_find(km, m1, k1, m2, k2)
in
  if ige(idx, 0) then km_set_word(km, idx, KEYMAP_FLD_CMD, 0) else ()
end

implement keymap_event_mods(ev) = let
  val c = if ctrl_on(ev) then KEYMOD_CTRL else 0
  val a = if alt_on(ev) then KEYMOD_ALT else 0
  val s = if shift_on(ev) then KEYMOD_SHIFT else 0
in
  iadd(c, iadd(a, s))
end

implement keymap_event_key(ev) = ev_keysym(ev)

fun km_lookup_cmd(km: !Buf, m1: int, k1: int, m2: int, k2: int): Cmd = let
  val idx = km_find(km, m1, k1, m2, k2)
in
  if ige(idx, 0) then cmd_of_code(km_word(km, idx, KEYMAP_FLD_CMD)) else CMD_NONE
end

fun km_resolve_second(
  km: !Buf, ca: &Toggle >> _, cm: &int >> _, ck: &int >> _, mods: int, key: int
): Cmd = let
  val cancel = ieq(key, KEYCODE_ESCAPE) orelse (ine(anth_iand(mods, KEYMOD_CTRL), 0) andalso ieq(key, 103))
  val m1 = cm
  val k1 = ck
  val () = (ca := Off; cm := 0; ck := 0)
in
  if cancel then CMD_NONE else km_lookup_cmd(km, m1, k1, mods, key)
end

fun km_resolve_first(
  km: !Buf, ca: &Toggle >> _, cm: &int >> _, ck: &int >> _, mods: int, key: int
): Cmd =
  if km_has_prefix(km, mods, key) then let
    val () = (ca := On; cm := mods; ck := key)
  in
    CMD_NONE
  end else let
    val matched = km_lookup_cmd(km, mods, key, 0, 0)
    val no_ca = ieq(anth_iand(mods, iadd(KEYMOD_CTRL, KEYMOD_ALT)), 0)
  in
    if not(is_cmd(matched, CMD_NONE)) then matched
    else if no_ca andalso ilt(key, 256) then CMD_TEXT_INPUT
    else CMD_NONE
  end

implement keymap_resolve(km, ca, cm, ck, mods, key, act) =
  if is_off(act) then let
    val () = (ca := Off; cm := 0; ck := 0)
  in
    if ieq(key, KEYCODE_ESCAPE) then CMD_ESCAPE else CMD_NONE
  end else if is_on(ca) then km_resolve_second(km, ca, cm, ck, mods, key)
  else km_resolve_first(km, ca, cm, ck, mods, key)

implement keymap_resolve_wheel(km, ev) = let
  val mods = keymap_event_mods(ev)
  val key = if is_btn(button_of(ev_button(ev)), BtnWheelUp) then KEYCODE_WHEEL_UP else KEYCODE_WHEEL_DOWN
in
  km_lookup_cmd(km, mods, key, 0, 0)
end

#include "ui_workspace/commands/private/ui_keymap/keymap_names.hats"
#include "ui_workspace/commands/private/ui_keymap/keymap_parse.hats"
#include "ui_workspace/commands/private/ui_keymap/keymap_defaults.hats"

implement keymap_format_entry(km, idx, dst) = let
  val () = buffer_clear(dst)
  val n = keymap_count(km)
in
  if ige(idx, 0) andalso ilt(idx, n) then let
    val ccode = km_word(km, idx, KEYMAP_FLD_CMD)
    val cmd = cmd_of_code(ccode)
    val k2 = km_word(km, idx, KEYMAP_FLD_KEY2)
  in
    if igt(ccode, 0) then (
      keymap_format_chord(km_word(km, idx, KEYMAP_FLD_MOD1), km_word(km, idx, KEYMAP_FLD_KEY1), dst);
      if igt(k2, 0) then (buffer_append_string(dst, " "); keymap_format_chord(km_word(km, idx, KEYMAP_FLD_MOD2), k2, dst)) else ();
      buffer_append_string(dst, " -> ");
      buffer_append_string(dst, keymap_cmd_name(cmd))
    ) else ()
  end else ()
end
