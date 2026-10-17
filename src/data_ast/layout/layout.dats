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
macdef LH_LINES = 5
macdef LH_DATA = 6

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
  val () = buf_set32(layout, LH_LINES, 0)
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
  val () = buf_set32(layout, LH_VER, version)
  val () = buf_set32(layout, LH_KEY, key)
  val () = buf_set32(layout, LH_HEIGHT, height)
  val () = buf_set32(layout, LH_MODE, mode)
in
  buf_set32(layout, LH_WRAP, wrap)
end

implement layout_wrap(layout) = buf_get32(layout, LH_WRAP)
