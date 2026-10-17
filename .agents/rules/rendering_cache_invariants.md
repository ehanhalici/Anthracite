# Rendering Cache Invariant: Synchronous Visibility State

In Anthracite's rendering pipeline:
- `visual_layout_prepare` runs before `doc_layout_mode` to build wrapped `VisualRows`.
- `VisualRows` is cached against `doc_layout_version(d)`.
- Whenever folding state or version is updated (`doc_toggle`, `doc_toggle_deep`), all AST node visibility flags (`doc_node_hidden`) must be updated synchronously in `doc_compute_foldability`.
- `visual_projection_make` must always read synchronized visibility so that cached visual rows never store stale hidden masks.
