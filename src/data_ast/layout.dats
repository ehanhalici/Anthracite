#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "data_ast/layout.sats"

macdef LH_VER = 0
macdef LH_KEY = 1
macdef LH_HEIGHT = 2
macdef LH_MODE = 3
macdef LH_WRAP = 4
macdef LH_LINES = 5
macdef LH_DATA = 6

fun line_offset(index: int): int = imul(iadd(LH_DATA, imul(index, 2)), 4)
fun node_offset(index: int, line_count: int): int = imul(iadd(LH_DATA, iadd(imul(line_count, 2), imul(index, 2))), 4)

implement layout_open() = let
  val layout = buf_make(256)
  val () = buf_set32(layout, LH_VER, ~1)
  val () = buf_set32(layout, LH_KEY, 0)
  val () = buf_set32(layout, LH_HEIGHT, 0)
  val () = buf_set32(layout, LH_MODE, ~1)
  val () = buf_set32(layout, LH_WRAP, 80)
  val () = buf_set32(layout, LH_LINES, 0)
in
  layout
end

implement layout_dispose(layout) = buf_free(layout)

implement layout_line_need(index) = iadd(line_offset(index), 8)

implement layout_line_put(layout, index, y, step, line_count) = let
  val () = buf_set32(layout, idiv(line_offset(index), 4), y)
  val () = buf_set32(layout, iadd(idiv(line_offset(index), 4), 1), step)
in
  buf_set32(layout, LH_LINES, line_count)
end

implement layout_line_y(layout, index, line_count) =
  if ilt(index, 0) orelse ige(index, line_count) then 0
  else buf_get32(layout, idiv(line_offset(index), 4))

implement layout_line_step(layout, index, line_count) =
  if ilt(index, 0) orelse ige(index, line_count) then 0
  else buf_get32(layout, iadd(idiv(line_offset(index), 4), 1))

implement layout_node_need(index, line_count) = iadd(node_offset(index, line_count), 8)

implement layout_node_put_height(layout, index, height, line_count) = let
  val off = node_offset(index, line_count)
in
  buf_set32(layout, idiv(iadd(off, 4), 4), height)
end

implement layout_node_height(layout, index, line_count) =
  if ilt(index, 0) then 0
  else buf_get32(layout, idiv(iadd(node_offset(index, line_count), 4), 4))

implement layout_node_put_y(layout, index, y, line_count) = let
  val off = node_offset(index, line_count)
in
  buf_set32(layout, idiv(off, 4), y)
end

implement layout_node_y(layout, index, line_count) =
  if ilt(index, 0) then 0
  else buf_get32(layout, idiv(node_offset(index, line_count), 4))

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
