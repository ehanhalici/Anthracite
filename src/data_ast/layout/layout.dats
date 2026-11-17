#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "data_ast/layout/layout.sats"

macdef LH_VER = 0
macdef LH_KEY = 1
macdef LH_HEIGHT = 2
macdef LH_MODE = 3
macdef LH_WRAP = 4
macdef LH_RAW0 = 5
macdef LH_RAW1 = 6
macdef LH_LINES = 7
(* Inclusive line range whose visual row count changed since the last layout. *)
macdef LH_DIRTY0 = 8
macdef LH_DIRTY1 = 9
macdef LH_DATA = 10

macdef LAYOUT_RECORD_WORDS = 2
macdef LAYOUT_RECORD_BYTES = LAYOUT_RECORD_WORDS * WORD32_BYTES
macdef LAYOUT_FIELD_Y = 0
macdef LAYOUT_FIELD_EXTENT = 1
macdef LAYOUT_INITIAL_CAPACITY_BYTES = 256
macdef LAYOUT_DEFAULT_WRAP_COLUMNS = 80

fun line_base_word(index: int): int = iadd(LH_DATA, imul(index, LAYOUT_RECORD_WORDS))
fun node_base_word(index: int, line_count: int): int =
  iadd(line_base_word(line_count), imul(index, LAYOUT_RECORD_WORDS))

implement layout_open() = let
  val layout = buf_make(LAYOUT_INITIAL_CAPACITY_BYTES)
  val () = buf_set32(layout, LH_VER, ~1)
  val () = buf_set32(layout, LH_KEY, 0)
  val () = buf_set32(layout, LH_HEIGHT, 0)
  val () = buf_set32(layout, LH_MODE, ~1)
  val () = buf_set32(layout, LH_WRAP, LAYOUT_DEFAULT_WRAP_COLUMNS)
  val () = buf_set32(layout, LH_RAW0, ~1)
  val () = buf_set32(layout, LH_RAW1, ~2)
  val () = buf_set32(layout, LH_LINES, 0)
  val () = buf_set32(layout, LH_DIRTY0, ~1)
  val () = buf_set32(layout, LH_DIRTY1, ~2)
in
  layout
end

implement layout_dispose(layout) = buf_free(layout)

implement layout_line_need(index) = imul(iadd(line_base_word(index), LAYOUT_RECORD_WORDS), WORD32_BYTES)

implement layout_line_put(layout, index, y, step, line_count) = let
  val base = line_base_word(index)
  val () = buf_set32(layout, iadd(base, LAYOUT_FIELD_Y), y)
  val () = buf_set32(layout, iadd(base, LAYOUT_FIELD_EXTENT), step)
in
  buf_set32(layout, LH_LINES, line_count)
end

implement layout_line_y(layout, index, line_count) =
  if ilt(index, 0) orelse ige(index, line_count) then 0
  else buf_get32(layout, iadd(line_base_word(index), LAYOUT_FIELD_Y))

implement layout_line_step(layout, index, line_count) =
  if ilt(index, 0) orelse ige(index, line_count) then 0
  else buf_get32(layout, iadd(line_base_word(index), LAYOUT_FIELD_EXTENT))

implement layout_node_need(index, line_count) =
  imul(iadd(node_base_word(index, line_count), LAYOUT_RECORD_WORDS), WORD32_BYTES)

implement layout_node_put_height(layout, index, height, line_count) = let
  val base = node_base_word(index, line_count)
in
  buf_set32(layout, iadd(base, LAYOUT_FIELD_EXTENT), height)
end

implement layout_node_height(layout, index, line_count) =
  if ilt(index, 0) then 0
  else buf_get32(layout, iadd(node_base_word(index, line_count), LAYOUT_FIELD_EXTENT))

implement layout_node_put_y(layout, index, y, line_count) = let
  val base = node_base_word(index, line_count)
in
  buf_set32(layout, iadd(base, LAYOUT_FIELD_Y), y)
end

implement layout_node_y(layout, index, line_count) =
  if ilt(index, 0) then 0
  else buf_get32(layout, iadd(node_base_word(index, line_count), LAYOUT_FIELD_Y))

implement layout_cache_matches(layout, version, key, mode) =
  buf_get32(layout, LH_VER) = version andalso buf_get32(layout, LH_KEY) = key andalso buf_get32(layout, LH_MODE) = mode

implement layout_cache_height(layout) = buf_get32(layout, LH_HEIGHT)

implement layout_cache_store(layout, version, key, height, mode, wrap) = let
  val () = buf_set32(layout, LH_DIRTY0, ~1)
  val () = buf_set32(layout, LH_DIRTY1, ~2)
  val () = buf_set32(layout, LH_VER, version)
  val () = buf_set32(layout, LH_KEY, key)
  val () = buf_set32(layout, LH_HEIGHT, height)
  val () = buf_set32(layout, LH_MODE, mode)
in
  buf_set32(layout, LH_WRAP, wrap)
end

implement layout_wrap(layout) = buf_get32(layout, LH_WRAP)

implement layout_raw_matches(layout, raw0, raw1) =
  buf_get32(layout, LH_RAW0) = raw0 andalso buf_get32(layout, LH_RAW1) = raw1

implement layout_raw_store(layout, raw0, raw1) = let
  val () = buf_set32(layout, LH_RAW0, raw0)
in
  buf_set32(layout, LH_RAW1, raw1)
end

implement layout_dirty_first(layout) = buf_get32(layout, LH_DIRTY0)
implement layout_dirty_last(layout) = buf_get32(layout, LH_DIRTY1)
implement layout_mark_dirty(layout, first, last) = let
  val old0 = buf_get32(layout, LH_DIRTY0)
  val old1 = buf_get32(layout, LH_DIRTY1)
  val empty = ilt(old0, 0)
  val () = buf_set32(layout, LH_DIRTY0, if empty then first else imin(old0, first))
in
  buf_set32(layout, LH_DIRTY1, if empty then last else imax(old1, last))
end
