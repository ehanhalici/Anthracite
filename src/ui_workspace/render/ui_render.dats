#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
#include "data_text/utf8/utf8_encoding.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef EMBEDDED_HEIGHT_ANCHOR_INITIAL_BYTES = 8
macdef BIND_ONE_REL_INITIAL_BYTES = 8
macdef BIND_ONE_FULL_INITIAL_BYTES = 8
macdef BIND_ONE_SHOWN_INITIAL_BYTES = 8
macdef BIND_ONE_DUMMY_INITIAL_BYTES = 1
macdef DRAW_NODE_IMAGE_REL_INITIAL_BYTES = 8
macdef DRAW_NODE_IMAGE_FULL_INITIAL_BYTES = 8
macdef DRAW_NODE_IMAGE_SHOWN_INITIAL_BYTES = 8
macdef DRAW_NODE_EMBED_SHOWN_INITIAL_BYTES = 8
macdef DRAW_NODE_EMBED_REL_INITIAL_BYTES = 8
macdef DRAW_NODE_EMBED_FULL_INITIAL_BYTES = 8
macdef DRAW_NODE_EMBED_ANCHOR_INITIAL_BYTES = 8
macdef CONVERT_CMD_CBUF_INITIAL_BYTES = 32
macdef DRAW_NODE_MATHB_BUFFER_INITIAL_BYTES = 64
macdef DRAW_LEAF_MATH_INLINE_BUFFER_INITIAL_BYTES = 32
macdef DRAW_TABROW_EMPTY_B_INITIAL_BYTES = 0
macdef TAB_HIT_TEST_EMPTY_B_INITIAL_BYTES = 0


staload "mem.sats"
staload "core_runtime/performance.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/resources/font.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/document/doc_anchor.sats"
staload "data_ast/syntax/ast.sats"
staload "data_image/image.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/render/ui_render.sats"
staload "ui_workspace/embed/embedded_doc.sats"
staload "ui_workspace/widgets/ui_widgets.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_ast/layout/doc_geometry.sats"
staload "data_ast/layout/layout_internal.sats"
staload "ui_workspace/visual/visual_layout.sats"
staload "ui_workspace/visual/visual_paint.sats"
staload "ui_workspace/visual/visual_query.sats"
staload "data_font/text/font_text.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "ui_workspace/visual/visual_decor.sats"

macdef UI_GUTTER_WIDTH = 44
macdef UI_WRAP_CELL_WIDTH = 9
macdef MAX_EMBED_DEPTH = 8

%{#
#include "data_font/legacy/arabic.cats"
%}


(* Private implementation groups share this owner and its linear representation. *)
#include "ui_workspace/render/private/ui_render/embed_work.hats"
#include "ui_workspace/render/private/ui_render/anth_ui_caret_adv.hats"
#include "ui_workspace/render/private/ui_render/doc_buf_push_slice.hats"
#include "ui_workspace/render/private/ui_render/embed_view_cache.hats"
#include "ui_workspace/render/private/ui_render/embed_visible_pins.hats"
#include "ui_workspace/render/private/ui_render/embed_document_cache.hats"
#include "ui_workspace/render/private/ui_render/image_slice_size.hats"
#include "ui_workspace/render/private/ui_render/bind_mathb_height.hats"
#include "ui_workspace/render/private/ui_render/line_y_bsearch.hats"
#include "ui_workspace/render/private/ui_render/editor_colx.hats"
#include "ui_workspace/render/private/ui_render/heading_top_pad.hats"
#include "ui_workspace/render/private/ui_render/is_latex_alpha.hats"
#include "ui_workspace/render/private/ui_render/convert_sub.hats"
#include "ui_workspace/render/private/ui_render/draw_leaf_styled.hats"
#include "ui_workspace/render/private/ui_render/sel_lines.hats"
#include "ui_workspace/render/private/ui_render/draw_tabrow_impl.hats"
#include "ui_workspace/render/private/ui_render/node_covering_impl.hats"
#include "ui_workspace/render/private/ui_render/embed_selection.hats"
