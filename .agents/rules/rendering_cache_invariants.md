# Rendering Cache Invariant: Synchronous Visibility State

In Anthracite's rendering pipeline:
- `visual_layout_prepare` runs before `doc_layout_mode` to build wrapped `VisualRows`.
- `VisualRows` is cached against `doc_layout_version(d)`.
- Whenever folding state or version is updated (`doc_toggle`, `doc_toggle_deep`), all AST node visibility flags (`doc_node_hidden`) must be updated synchronously in `doc_compute_foldability`.
- `visual_projection_make` must always read synchronized visibility so that cached visual rows never store stale hidden masks.
- Large top-level documents wrap visible-first: lines not shaped yet keep one placeholder row (`VISUAL_ROW_PENDING_WIDTH`) and `visual_rows_pending` > 0. Code that needs exact rows for a line outside the viewport must call `visual_layout_wrap_range` (or `visual_layout_prepare` for every line); painting and hit-testing assume the viewport band was settled by `visual_layout_prepare_band`.
- Shaping can lazily load font faces, which changes `visual_layout_key`; re-key rows after shaping (as `wrap_stored` does), never before.
- Changing visual rows without a document edit must call `doc_layout_mark_rows` (incremental relayout); anything that changes node visibility, widget heights or text must bump the version instead, because `doc_layout_update` skips `doc_layout_ast_prepare`.
- Lines shaped by workers come back as rows + paragraph analyses only (plans hold face tokens of the worker's Font); `VisualKey.build` stamps every rows build so worker results for an older build are dropped. A lazily loaded face (font id < 0 → loaded) does not invalidate rows (`visual_key_context_matches`).
