# Folding Algorithm Invariant: Subtree Extent Propagation

In stack-based boundary scanners:
- Each stack frame tracking indented blocks maintains `last`, the line number of its furthest descendant.
- When `stack_pop_one` removes an item, `stack_propagate_last` MUST propagate
  its `last` upward to the remaining parent using the maximum of both extents.
- This guarantees that collapsing any ancestor item completely encompasses all nested subtrees, sibling sublists, and deeper descendants.

The line/stack scan and visibility sweep are monotonic. The current insertion
sort of regions can still take O(R²); do not describe the entire pipeline as
linear until BUG-006 is resolved. `tests/folds` checks region boundaries and
single-region visibility against an interval oracle.
