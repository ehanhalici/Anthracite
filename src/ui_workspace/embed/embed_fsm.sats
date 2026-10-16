%{#
#include "ui_workspace/embed/embed_fsm.cats"
%}

#define EMBED_STATE_UNLOADED 0
#define EMBED_STATE_RESOLVING 1
#define EMBED_STATE_CACHED 2
#define EMBED_STATE_FAILED 3

datatype EmbedState =
  | EmbedUnloaded
  | EmbedResolving
  | EmbedCached of int
  | EmbedFailed

fun embed_fsm_query(path: string, colw: int, lh: int, out_h: &int >> _): int = "mac#anth_embed_fsm_query"
fun embed_fsm_store(path: string, colw: int, lh: int, h: int): void = "mac#anth_embed_fsm_store"
fun embed_fsm_fail(path: string, colw: int, lh: int): void = "mac#anth_embed_fsm_fail"
fun embed_fsm_clear(): void = "mac#anth_embed_fsm_clear"

fun embed_state_of(code: int, h: int): EmbedState
