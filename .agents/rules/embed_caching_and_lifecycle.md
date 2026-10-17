# Embed Document Lifecycle & Caching Invariant

1. **Zero Per-Frame I/O**:
   - `draw_doc`, `draw_nodes`, and `bind_media` must NEVER call `doc_open()`, `doc_load()`, or disk reading functions directly on every frame.
   - Resolve transcluded notes (`![[note]]`) through the owned embed cache. A
     cache miss or mtime change may load a document; a cache hit must reuse it.

2. **Cache Invalidation & Freshness**:
   - Keys use the resolved path produced by the media/path helpers. Do not claim
     canonical `realpath` normalization unless the implementation provides it.
   - Cache hit validation uses `embedded_source_stamp`: the same nonempty VFS
     shadow policy as Doc loading, otherwise the physical file. Compare source
     kind and stat seconds/nanoseconds/size/device/inode, not integer-second mtime.
     Reuse avoids loading/parsing; metadata checks still have a cost. Never
     restore the removed global path-only embed height table.

3. **Memory Ownership & Leak Prevention**:
   - The embed cache holds ownership of cached `Doc` instances.
   - Eviction and shutdown must call `doc_free(child)` and release the path buffer.
     `mem_live` before/after checks cover tracked buffers, not all C/GPU resources.
   - Canonical Doc/AST ownership is separate from `DocGeometry` view ownership.
     Native view keys include exact source range, width, font IDs/generations,
     metrics and projection. Never clone a Doc/AST merely for another width.
   - View cache policy is 128 entries / 64 MiB of conservatively charged owned
     payload. Keep the selected source and fitting selected view pinned. Release
     the view's row plans on eviction; their spans must not be aliased.
   - `EmbedViewPending` is an active-path guard, not a cached height or failed
     Doc. End every successful obtain/save pair, including measure and hit paths.

Implementation: `src/ui_workspace/render/ui_render.dats` and its private groups.
