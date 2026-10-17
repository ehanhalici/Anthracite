#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "data_ast/document/doc.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "search/ix_match.sats"

#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef OPEN_LOADED_TITLE_INITIAL_BYTES = 8
macdef REPLACE_LOADED_TITLE_INITIAL_BYTES = 8



(* Private implementation groups share this owner and its linear representation. *)
#include "ui_workspace/tabs/private/ui_tab/touch_doc.hats"
#include "ui_workspace/tabs/private/ui_tab/run_cmd.hats"
#include "ui_workspace/tabs/private/ui_tab/replace_loaded.hats"
#include "ui_workspace/tabs/private/ui_tab/tabs_jump.hats"
