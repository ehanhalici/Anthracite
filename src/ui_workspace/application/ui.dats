#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef MAKE_EMPTY_TABS_TITLE_INITIAL_BYTES = 16
macdef MAKE_EMPTY_TABS_PATH_INITIAL_BYTES = 4
macdef RESOLVE_VAULT_BUFFER_ACT_INITIAL_BYTES = 256
macdef OPEN_RESOLVE_VAULT_BUFFER_INITIAL_BYTES = 256
macdef OPEN_SCAN_FONTS_FPATHS_INITIAL_BYTES = 2048
macdef OPEN_SCAN_FONTS_FNAMES_INITIAL_BYTES = 1024
macdef OPEN_SCAN_FONTS_FMETA_INITIAL_BYTES = 512
macdef OPEN_SCAN_VAULTS_VPATHS_INITIAL_BYTES = 2048
macdef OPEN_SCAN_VAULTS_VNAMES_INITIAL_BYTES = 512
macdef OPEN_SCAN_VAULTS_VMETA_INITIAL_BYTES = 512
macdef OPEN_INIT_SESSION_FPATH_INITIAL_BYTES = 256
macdef APP_RECORD_MAKE_CLIP_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_PROMPTB_INITIAL_BYTES = 256
macdef APP_RECORD_MAKE_QUERY_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_TREE_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_TMETA_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_TOPEN_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_HITS_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_HMETA_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_IXF_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_IXS_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_IXP_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_IXB_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_IXQ_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_HJUMP_INITIAL_BYTES = 64
macdef APP_RECORD_MAKE_SCRATCH_INITIAL_BYTES = 4096
macdef APP_RECORD_MAKE_IMGPATH_INITIAL_BYTES = 64
macdef APP_OPEN_TAB_PANE_INITIAL_BYTES = 16
macdef APP_OPEN_OPEN_DIRS_INITIAL_BYTES = 128
macdef CHECK_ROW_OPEN_TMP_INITIAL_BYTES = 256
macdef DRAW_TREE_ROW_BASE_INITIAL_BYTES = 8
macdef DRAW_CONFIG_FONT_ROW_PBUF_INITIAL_BYTES = 256
macdef DRAW_CONFIG_FONT_ROW_NBUF_INITIAL_BYTES = 64
macdef DRAW_VAULT_ITEM_NBUF_INITIAL_BYTES = 64
macdef DRAW_VAULT_ITEM_PBUF_INITIAL_BYTES = 256
macdef WIKI_TARGET_PREP_REL_INITIAL_BYTES = 8
macdef WIKI_TARGET_PREP_FULL_INITIAL_BYTES = 8
macdef HANDLE_LINK_CLICK_URL_INITIAL_BYTES = 16
macdef APP_WIKI_OPEN_ANCHOR_INITIAL_BYTES = 8
macdef APP_WIKI_OPEN_SHOWN_INITIAL_BYTES = 8
macdef CLOSE_ACTIVE_TAB_BUFFER_INITIAL_BYTES = 4
macdef CLOSE_ACTIVE_TAB_BUFFER_ALTERNATE_INITIAL_BYTES = 16
macdef NEW_EMPTY_TAB_BUFFER_INITIAL_BYTES = 4
macdef NEW_EMPTY_TAB_BUFFER_ALTERNATE_INITIAL_BYTES = 16
macdef FILL_DIR_CWD_CWD_BUF_INITIAL_BYTES = 512
macdef OPEN_ROW_CUR_INITIAL_BYTES = 8
macdef FILL_NODE_PATH_REL_INITIAL_BYTES = 64
macdef FILL_NODE_PATH_FULL_INITIAL_BYTES = 160
macdef COPY_NODE_HERE_SHOWN_INITIAL_BYTES = 160
macdef OPEN_HIT_HITFILE_INITIAL_BYTES = 16
macdef OPEN_CREATED_FILE_NEW_FILE_INITIAL_BYTES = 8
macdef HANDLE_PROMPT_SUBMISSION_DIR_INITIAL_BYTES = 8
macdef HANDLE_PROMPT_SUBMISSION_CUR_INITIAL_BYTES = 8
macdef SELECT_VAULT_ROW_PBUF_INITIAL_BYTES = 256
macdef HANDLE_CONTEXT_MENU_ACTION_CUR_INITIAL_BYTES = 8
macdef TREE_OPEN_FILE_CUR_INITIAL_BYTES = 8
macdef MOVE_DRAGGED_FILE_SRCP_INITIAL_BYTES = 8
macdef MOVE_DRAGGED_FILE_DSTP_INITIAL_BYTES = 8
macdef MOVE_DRAGGED_FILE_NAME_INITIAL_BYTES = 8
macdef MOVE_DRAGGED_FILE_FINAL_INITIAL_BYTES = 8


staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/selftest_fixture.sats"
staload "os/diag.sats"
staload "core_platform/platform.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/resources/font.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/document/doc_anchor.sats"
staload "data_ast/syntax/ast.sats"
staload "data_image/image.sats"
staload "ui_workspace/application/ui.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tree/ui_tree.sats"
staload "ui_workspace/search/ui_search.sats"
staload "ui_workspace/commands/ui_menu.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/visual/visual_navigation.sats"
staload "ui_workspace/visual/source_navigation.sats"
staload "ui_workspace/render/ui_render.sats"
staload "ui_workspace/widgets/ui_widgets.sats"
staload "ui_workspace/text/ui_text_engine.sats"
staload "config/conf.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "search/ix_store.sats"
staload "search/ix_fold.sats"
staload "search/ix_query.sats"
staload "search/ix_build.sats"
staload "search/ix_match.sats"
staload "search/ix_test.sats"
staload "ui_workspace/state/editor_fsm.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "ui_workspace/application/private/ui/iand.hats"
#include "ui_workspace/application/private/ui/init_vault_tabs.hats"
#include "ui_workspace/application/private/ui/free_input_bufs.hats"
#include "ui_workspace/application/private/ui/tree_expander_hit.hats"
#include "ui_workspace/application/private/ui/draw_side_body.hats"
#include "ui_workspace/application/private/ui/ensure_index_step.hats"
#include "ui_workspace/application/private/ui/doc_seek_anchor.hats"
#include "ui_workspace/application/private/ui/wiki_open_file.hats"
#include "ui_workspace/application/private/ui/fill_dir_vault_or_cwd.hats"
#include "ui_workspace/application/private/ui/clear_node.hats"
#include "ui_workspace/application/private/ui/tab_cycle_next.hats"
#include "ui_workspace/application/private/ui/topbar_toggle_search.hats"
#include "ui_workspace/application/private/ui/down_menu_clip.hats"
#include "ui_workspace/application/private/ui/open_general_context.hats"
#include "ui_workspace/application/private/ui/pane_start_x.hats"
#include "ui_workspace/application/private/ui/on_up_drop.hats"
#include "ui_workspace/application/private/ui/selftest_gutter_arrow.hats"
#include "ui_workspace/application/private/ui/selftest_session_roundtrip.hats"
