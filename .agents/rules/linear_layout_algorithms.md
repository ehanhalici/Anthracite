# Linear-Time Document Layout Scaling Invariant

1. **Strict Prohibition of $O(L \times N)$ Line-Node Scans**:
   - Procedural functions calculating per-line metrics (`line_calc_step`, `doc_layout_widget_height`, `block_kind_at`) must never scan from node $0$ to node $N$ on every line.
   - Functions correlating lines with AST nodes must use monotonic cursor sweeps ($O(L + N)$) or interval binary searches ($O(L \log N)$).

2. **Word Wrap Search Efficiency**:
   - When fitting text to column width in `visual_wrap.dats`, avoid linear scanning of all candidate boundaries with repeated shaper evaluations.
   - Use binary search over candidate break boundaries or pre-accumulated glyph advances.
   - Preserve paragraph-resolved bidi levels/base and scripts when shaping a
     wrapped row. Use EGC-aligned `native_text_analysis_window`, then the line
     L1/order kernel; do not re-run AutoLtr paragraph analysis for each row.
   - Original UTF-8 length is explicit analysis metadata: canonical mark
     reordering can make the last normalized scalar's sourceEnd smaller.
