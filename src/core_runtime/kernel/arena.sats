(* Process-wide allocator behind every ATS allocation (ATS_MEMALLOC_USER),
   implemented in ATS2 by core_runtime/kernel/arena.dats over the root cells
   and syscalls of kernel.cats. It never allocates itself.

   Layout: one large virtual reservation (min(RAM/4, 64 GB), or
   ANTHRACITE_ARENA_MAX), committed in big steps (first 100 MB with
   MADV_HUGEPAGE and a background prefault, then 64 MB), carved into 2 MB
   segments of 64 KB pages. Each thread owns its segments and keeps
   per-size-class free lists (40 classes up to 32 KB), so the fast path
   touches only thread-private cache lines. A block freed by another thread is
   pushed onto its owner's remote stack (one CAS) and recycled by the owner
   later. Blocks above 32 KB are spans of whole segments, cached for reuse
   (exact size first, else the smallest bigger span). Memory is never returned
   to the OS while running. A finished thread's heap is adopted by the next
   new thread.

   Every block address read back from memory (free lists, remote stacks,
   cached spans) is checked against the reservation and its segment header
   before use; a violated invariant aborts instead of corrupting memory.

   ANTHRACITE_ARENA=0 routes everything to libc (comparison / diagnosis). *)
%{#
#include "core_runtime/kernel/kernel.cats"
%}
fun arena_malloc(size: size_t): ptr = "ext#anth_arena_malloc"
fun arena_calloc(count: size_t, size: size_t): ptr = "ext#anth_arena_calloc"
fun arena_realloc(p: ptr, size: size_t): ptr = "ext#anth_arena_realloc"
fun arena_free(p: ptr): void = "ext#anth_arena_free"
fun arena_usable(p: ptr): size_t = "ext#anth_arena_usable"
(* For the block the calling thread freed last: the statistics slot + 1 of
   the thread owning its heap when that is another thread, else 0 (own block,
   or a block outside the arena). Read right after the free, on the same
   thread; the free path already holds the segment header, so this costs no
   extra lookup. *)
fun arena_freed_slot(): int = "ext#anth_arena_freed_slot"
fun arena_set_owner_slot(slot: int): void = "ext#anth_arena_set_owner_slot"
(* 0 reserved, 1 committed, 2 segments, 3 heaps, 4 remote frees, 5 libc fallbacks, 6 enabled. *)
fun arena_stat(field: int): lint = "ext#anth_arena_stat"
fun arena_heap_address(heap: int): ptr = "ext#anth_arena_heap_address"
fun arena_heap_size(): lint = "ext#anth_arena_heap_size"
(* Cold slow paths of the allocation fast path (first call, first use in a
   thread); kernel.cats declares them cold and out of line. *)
fun arena_start_init(): void = "ext#anth_arena_start_init"
fun arena_first_heap(): int = "ext#anth_arena_first_heap"
(* pthread key destructor and prefault thread (C start routines). *)
fun arena_heap_abandon(value: ptr): void = "ext#anth_arena_heap_abandon"
fun arena_populate(bytes: ptr): ptr = "ext#anth_arena_populate"
(* ATS runtime hooks (ccomp/runtime/pats_ccomp_memalloc_user.h). *)
fun arena_hook_malloc(size: size_t): ptr = "ext#atsruntime_malloc_user"
fun arena_hook_calloc(count: size_t, size: size_t): ptr = "ext#atsruntime_calloc_user"
fun arena_hook_realloc(p: ptr, size: size_t): ptr = "ext#atsruntime_realloc_user"
fun arena_hook_free(p: ptr): void = "ext#atsruntime_mfree_user"
