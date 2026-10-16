# Embed Document Lifecycle & Caching Invariant

1. **Zero Per-Frame I/O**:
   - `draw_doc`, `draw_nodes`, and `bind_media` must NEVER call `doc_open()`, `doc_load()`, or disk reading functions directly on every frame.
   - Resolve transcluded notes (`![[note]]`) through the owned embed cache. A
     cache miss or mtime change may load a document; a cache hit must reuse it.

2. **Cache Invalidation & Freshness**:
   - Keys use the resolved path produced by the media/path helpers. Do not claim
     canonical `realpath` normalization unless the implementation provides it.
   - Cache hit validation checks `fs_mtime`. Reuse avoids loading/parsing;
     path comparison and freshness checking still have a cost.

3. **Memory Ownership & Leak Prevention**:
   - The embed cache holds ownership of cached `Doc` instances.
   - Eviction and shutdown must call `doc_free(child)` and release the path buffer.
     `mem_live` before/after checks cover tracked buffers, not all C/GPU resources.

Implementation: `src/ui_workspace/render/ui_render.dats` and its private groups.
