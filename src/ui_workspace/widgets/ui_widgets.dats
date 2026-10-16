#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef CODE_DRAW_LINE_NUM_NUM_B_INITIAL_BYTES = 16


staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/widgets/ui_widgets.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "ui_workspace/widgets/private/ui_widgets/is_vertical.hats"
#include "ui_workspace/widgets/private/ui_widgets/ui_button.hats"
#include "ui_workspace/widgets/private/ui_widgets/fit_bytes.hats"
