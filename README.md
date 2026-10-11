# Anthracite

Anthracite is a lightweight, zero-dependency Markdown editor and viewer built with **ATS2** (Applied Type System). It combines compile-time formal verification with hardware-accelerated rendering to deliver an uncompromising writing and reading experience—without the overhead of web runtimes or heavy widget toolkits.

---

## Philosophy & Architecture

Most modern document editors bundle an entire web browser, trading hundreds of megabytes of memory and battery life for basic text manipulation. Anthracite is engineered under a different set of constraints:

- **Formally Verified Safety (ATS2):** Leveraging ATS2's dependent types and linear logic, critical invariants such as memory management, pointer validity, and buffer boundaries are proved at compile time. Memory leaks, use-after-free, and null dereferences are eliminated before execution—without a garbage collector.
- **Zero Runtime Dependencies:** Anthracite compiles down to a standalone native binary. There is no Electron, no WebKit, and no reliance on large GUI toolkits like GTK or Qt. Window management connects directly to the native display server (X11), and drawing is handled via modern, hardware-accelerated OpenGL.
- **True 0% Idle Footprint:** The event loop is strictly event-driven. When you are reading or pausing between keystrokes, socket polling keeps CPU utilization at absolute zero.
- **Sub-Millisecond Keystroke Response:** Parsing is backed by an incremental Abstract Syntax Tree (AST). Changes recalculate only affected subtrees rather than re-parsing entire documents, delivering instant rendering and smooth typing cadence even in large files.

---

## Features

### Editing & Reading
- **Centered Typography Canvas:** Mathematically centered reading column conforming to optimal typographic line-length standards.
- **Obsidian & CommonMark Support:** Native handling for CommonMark, GFM tables, task lists, code blocks, callouts, and Wikilinks (`[[Page]]`, `![[Embed]]`).
- **GPU Glyph Pipeline:** Custom texture-atlas glyph cache with precise kerning and high-DPI font rendering.
- **Direct Image Rendering:** Native in-engine image decoding and OpenGL texture binding without third-party image libraries.

### Workspace Ergonomics
- **Split View & Tab Management:** Rearrange tabs or drag to split views vertically for side-by-side editing and reference.
- **Workspace Navigation:** Fast file-tree drawer and contextual fuzzy document search.
- **Keyboard-Centric Flow:** Intuitive shortcuts designed for uninterrupted writing and navigation.

---

## Performance Profile

| Metric | Anthracite | Typical Web-Based Editor |
| :--- | :--- | :--- |
| **Startup Time** | Instant (< 50ms) | 1.5s – 4.0s |
| **Memory Footprint** | Lightweight (~10–25 MB) | 250 MB – 1 GB+ |
| **Runtime Overhead** | None (Zero GC pauses) | V8 / Chromium runtime |
| **Safety Guarantees** | Proven at compile time via linear types | Runtime exceptions |
| **Idle CPU Usage** | 0.0% | Background thread churn |

---

## Summary

Anthracite treats text and notes as essential tools that deserve systems-level engineering: predictable, robust, and completely independent.
