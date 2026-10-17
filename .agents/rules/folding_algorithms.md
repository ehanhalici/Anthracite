# Folding Algorithm Invariant: Subtree Extent Propagation

In stack-based boundary scanners:
- Each stack frame tracking indented blocks maintains `last`, the line number of its furthest descendant.
- When `stack_pop_one` removes an item, `stack_propagate_last` MUST propagate
  its `last` upward to the remaining parent using the maximum of both extents.
- This guarantees that collapsing any ancestor item completely encompasses all nested subtrees, sibling sublists, and deeper descendants.

The line/stack scan and visibility sweep are monotonic. Region sorting uses
stable four-pass radix sorting over signed 32-bit owners: O(R) time and O(R)
scratch storage. Preserve complete records and equal-owner insertion order.
`region_sort_contracts` checks stability and actual loop work, including reverse
inputs. `tests/folds` checks boundaries and visibility against an interval oracle.
