#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "data_ast/document/doc.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "config/conf.sats"

macdef MAX_CONF_FILE_SIZE = 10000000
macdef BUF_SZ_PATH = 256
macdef BUF_SZ_NAME = 64
macdef BUF_SZ_CONTENT = 4096
macdef BUF_SZ_LARGE = 8192
macdef BUF_SZ_PATHS = 1024

macdef KEY_ACTIVE_VAULT = "\"active_vault\""
macdef KEY_ACTIVE_VAULT_LEN = 14

macdef KEY_PATH = "\"path\""
macdef KEY_PATH_LEN = 6

macdef KEY_NAME = "\"name\""
macdef KEY_NAME_LEN = 6

macdef KEY_CONF_DIR = "\"conf_dir\""
macdef KEY_CONF_DIR_LEN = 10

macdef KEY_SCROLL = "\"scroll\""
macdef KEY_SCROLL_LEN = 8

macdef KEY_FONT_PATH = "\"font_path\""
macdef KEY_FONT_PATH_LEN = 11

macdef KEY_FONT_PX = "\"font_px\""
macdef KEY_FONT_PX_LEN = 9

macdef KEY_VIEWMODE = "\"viewmode\""
macdef KEY_VIEWMODE_LEN = 10

macdef KEY_SPLIT = "\"split\""
macdef KEY_SPLIT_LEN = 7

macdef KEY_ACTIVE = "\"active\""
macdef KEY_ACTIVE_LEN = 8

macdef KEY_RIGHT_ACTIVE = "\"right_active\""
macdef KEY_RIGHT_ACTIVE_LEN = 14

macdef KEY_TAB_COUNT = "\"tab_count\""
macdef KEY_TAB_COUNT_LEN = 11

macdef KEY_PANE = "\"pane\""
macdef KEY_PANE_LEN = 6

macdef KEY_OPEN_DIRS = "\"open_dirs\""
macdef KEY_OPEN_DIRS_LEN = 11

macdef KEY_SIDEBAR_OPEN = "\"sidebar_open\""
macdef KEY_SIDEBAR_OPEN_LEN = 14

macdef KEY_SIDEBAR_WIDTH = "\"sidebar_width\""
macdef KEY_SIDEBAR_WIDTH_LEN = 15

macdef CHAR_LBRACE = 123
macdef CHAR_RBRACE = 125

macdef VAULT_META_STRIDE_BYTES = 16
macdef VAULT_META_STRIDE_WORDS = 4
macdef VAULT_META_FIELD_POFF = 0
macdef VAULT_META_FIELD_PLEN = 1
macdef VAULT_META_FIELD_NOFF = 2
macdef VAULT_META_FIELD_NLEN = 3

macdef SESSION_DEFAULT_FONT_PX = 18
macdef SESSION_DEFAULT_VIEWMODE = 0
macdef SESSION_DEFAULT_SPLIT = 0
macdef SESSION_DEFAULT_ACTIVE = 0


(* Private implementation groups share this owner and its linear representation. *)
#include "config/private/conf/read_file.hats"
#include "config/private/conf/extract_vault_name.hats"
#include "config/private/conf/conf_set_active_vault.hats"
#include "config/private/conf/parse_one_tab.hats"
