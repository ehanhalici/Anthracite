#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "ui_workspace/embed/embed_fsm.sats"

implement embed_state_of(code, h) =
  if code = EMBED_STATE_CACHED then EmbedCached(h)
  else if code = EMBED_STATE_RESOLVING then EmbedResolving()
  else if code = EMBED_STATE_FAILED then EmbedFailed()
  else EmbedUnloaded()
