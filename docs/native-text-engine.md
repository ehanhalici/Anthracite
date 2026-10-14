# Native text engine: implementation status

Updated: 2026-10-14. This records an in-progress migration, not completion of
the full Unicode/OpenType rendering plan.

Normal workspace startup now enables native text rendering by default. Settings
shows `Yazi Tipi / Native`. Startup logs `engine=native ... status=ready`, and
`workspace_frame status=presented` confirms that the first frame actually
completed. Ordinary text now shares projected pixel-wrapped rows between
drawing, height, selection, pointer hit testing and vertical navigation.
Specialized blocks and full paragraph/ligature geometry migration remain open.

## Implemented

- `data_text/utf8`: strict Unicode scalar decoding, maximal-subpart replacement,
  original byte-span mapping, and linear ownership of the decoded arrays.
- UTF-8 decoding is split into five independently compiled modules (at most
  45 lines each): orchestration, byte/sequence decoding, measurement, storage
  and scalar access/ownership. Step results are flat records with nullary
  outcome tags, avoiding the old nonlinear payload allocation per scalar.
  A measurement pass sizes the three output arrays by emitted scalar count,
  not source byte count; a storage pass preserves original byte ranges.
  Span lengths above MAX_REC_FUEL are rejected before allocation rather than
  failing at the later fuel bridge. Empty arrays retain Buf's minimum capacity.
- `data_text/unicode_db`: checked, versioned Unicode 18 property database.
  `tools/unicode_compile.dats` builds it from the vendored official data in
  ATS2; neither Python's nor the operating system's Unicode version is used.
- `data_text/grapheme`: Unicode 18 extended grapheme boundaries, including its
  revised GB9c rule. All 853 official GraphemeBreakTest cases pass.
- `data_text/word_*`: Unicode 18 word boundaries. All 1,944 official
  WordBreakTest cases pass; class predicates, joining rules, state transitions
  and sequence traversal are separate modules.
- `data_text/line_*`: the Unicode 18 default line-breaking algorithm (UAX #14,
  revision 57), including HH hyphens, contextual quotations, numeric sequences,
  Brahmic syllables, regional-indicator parity and unassigned pictographic
  characters. All 19,346 official LineBreakTest cases pass, each with balanced
  buffer ownership. Forbidden, optional and mandatory boundaries are distinct
  types from an unresolved internal rule decision.
- Line breaking has 25 independently compiled implementation modules, each at
  most 128 lines. Property decoding, semantic predicate families, LB9/LB10
  combining-sequence construction, source-index storage, contextual FSM,
  ordered rule groups, traversal and boundary-map ownership are separate.
  Combining marks are collapsed only in temporary rule context; boundary
  indices still refer to the supplied scalar text. Context traversal is linear
  after property lookup and does not rescan growing space/number/RI sequences.
  This API produces legal opportunities, not pixel-width wrapping or a
  language dictionary/hyphenation service.
- `data_text/normalization_*`: all four Unicode 18 normalization forms
  (NFC, NFD, NFKC, NFKD). These implement recursive canonical/compatibility
  decomposition, algorithmic Hangul, stable canonical ordering and composition
  with the full composition-exclusion property. The renderer will use a
  source-mapped view; normalization does not rewrite the document buffer.
  All 20,171 official cases pass all 20 specified relations (403,420 checks).
  The remaining 1,094,910 Unicode scalars also pass all four identity checks
  (4,379,640 additional checks), with balanced buffer ownership.
- Normalization has 29 independently compiled implementation modules, each
  at most 77 lines. Model, data access, row encoding, errors, loading, source
  ingestion, dependency graph, ordering, composition and generation contracts
  are separate `.sats` interfaces. Its phase-indexed linear intermediate text
  prevents composition before canonical ordering.
- `tools/normalization_compile.dats` builds the versioned normalization asset
  in ATS2 from the vendored UnicodeData and DerivedNormalizationProps files.
  Dependency processing is topological; data ingestion checks mapping spans,
  scalar validity, ordering, computed depths/expansion lengths, exclusion flags
  and composition pairs. It rejects cycles and cannot override algorithmic
  Hangul with inconsistent explicit rows. Error values are flat records,
  avoiding unowned error-payload allocations under `ATS_MEMALLOC_LIBC`.
- `data_text/bidi_*`: native Unicode 18 paragraph-level resolution through
  P1–I2, line-local L1/L2 ordering, paired brackets (BD16/N0) and L4 codepoint
  mirror lookup. Isolate matching, explicit levels, run topology, weak/neutral
  resolution, implicit levels, paragraph storage and line ordering are separate
  independently compiled ATS2 modules. Both official conformance sets pass:
  91,707 BidiCharacterTest cases and 770,241 BidiTest direction combinations.
  Every test case checks balanced buffer ownership.
  Run-sequence scratch arrays are sized to the sequence itself, not the whole
  paragraph; a regression test enforces this allocation boundary.
- The BiDi document facade keeps immutable paragraph levels; wrapped lines
  borrow those levels and produce source-indexed visual orders independently.
  Tests cover mixed-direction paragraphs, CRLF paragraph boundaries, bracket
  source offsets, empty documents and trailing whitespace after wrapping.
- `data_text/unicode_sort`: stable scalar-key radix ordering. The mirror
  reader accepts the official Unicode 18 source's out-of-order appended rows,
  sorts once at ingestion and rejects duplicates before binary lookup.
- `data_text/unicode_property`: kind-indexed property maps prevent using a BiDi
  table as a word/joining table. The separate symbol parser, source reader and
  writer compile Word_Break, Bidi_Class, Joining_Type, Line_Break,
  East_Asian_Width and General_Category data in ATS2, including the `@missing`
  defaults for unassigned codepoints. New original inputs were extracted from
  the same pinned Unicode 18 archive; its SHA-256 was reverified.
- `data_font/sfnt`: a CPU-only static TrueType reader. It checks the directory,
  table spans and overlaps, required metric tables, `loca`, and Unicode
  `cmap` 4/12 structures and glyph IDs. It preserves zero `hmtx` advances and
  the shared advance of the trailing left-side-bearing entries.
- `data_font/glyph_component`: checked compound-component records, signed XY
  offsets versus unsigned point indices, affine matrix composition, scaled
  and unscaled offsets, and the specified off-diagonal matrix order.
- `data_font/opentype_*`: checked Coverage formats 1/2, ClassDef formats 1/2,
  and packed Device formats 1/2/3. Coverage indices are continuous across
  strictly ordered, disjoint ranges; ClassDef gaps yield class zero. Device
  deltas are signed, most-significant-first 2/4/8-bit pixel corrections, with
  checked padding and array bounds. VariationIndex is a distinct parsed result,
  not something that can be passed to the pixel-adjustment API.
  Font glyph counts must fit the unsigned 16-bit `maxp.numGlyphs` field:
  1–65,535 glyphs, with glyph IDs strictly below that count.
- `data_font/gdef_*`: GDEF 1.0/1.2/1.3 headers and immediate offsets, glyph
  classes, mark attachment classes, and mark-glyph-set coverage tables.
  Mark sets use their specified 32-bit offsets, may overlap, and keep owned
  compact descriptors instead of copying font subtables. Missing classes
  remain explicitly unclassified; glyph-class values outside 0–4 are rejected.
  These are separate GDEF capabilities, not a claim of full GDEF support.
- Lookup flags are typed metadata. Context filtering preserves the precedence
  of IgnoreMarks over mark-set filtering over mark attachment classes. The
  context matcher receives an already eligible initial glyph; the outer lookup
  traversal must filter the current glyph too, before testing coverage. The
  context-only helper does not provide that traversal. HarfBuzz's
  [forward/backward lookup traversal](https://github.com/harfbuzz/harfbuzz/blob/main/src/hb-ot-layout.cc)
  checks current-glyph properties explicitly. The RightToLeft lookup bit does
  not become a paragraph-direction heuristic.
- OpenType/GDEF now has 16 independently compiled implementation modules,
  each at most 48 lines. Models, byte/offset access, parsing, binary queries,
  packed deltas, lookup flags, GDEF classes and mark-set ownership are separate.
  Parsed views borrow immutable font bytes; no HarfBuzz/FreeType runtime
  dependency, algorithmic C, extra `assume` or unsafe casts were added.
- `data_font/ot_layout_*`: GSUB/GPOS 1.0/1.1 shared topology readers for
  ScriptList, Script, default/named LangSys, FeatureList, Feature and Lookup
  headers. Script/language tags are unique and sorted; duplicate feature tags
  and arbitrarily ordered/repeated feature/lookup references are supported.
  Required features survive optional feature selection. Missing scripts select
  DFLT when present; missing named languages select only the default language.
  Named and default language features are never combined implicitly.
- Lookup kinds are indexed by GSUB versus GPOS. Lookup flags check their
  required GDEF capabilities, mark-filter indices and optional header fields.
  Nonzero FeatureVariations offsets explicitly return `OtUnsupported`;
  FeatureParams contents and lookup subtable payloads are not interpreted yet.
  Extension lookup headers are an exception: GSUB 7/GPOS 9 validate their
  checked Offset32 target and enforce one target action across all subtables
  in the outer lookup, as required by the
  [GSUB](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub#lookup-type-7-substitution-subtable-extension)
  and [GPOS](https://learn.microsoft.com/en-us/typography/opentype/spec/gpos#lookup-type-9-positioning-subtable-extension)
  specifications. This does not validate the action-specific target payload.
  Accepted tables have phase 0 only: topology/header validation is not an
  executable shaping capability. Negative compilation tests enforce that
  distinction and reject exchanging positioning/substitution lookup kinds.
- Stage planning emits unique lookup IDs in LookupList order and compact CSR
  feature-owner arrays. A shared lookup retains all contributing feature IDs;
  duplicate references within one feature do not duplicate its ownership edge.
  This preserves information needed for later glyph-specific feature masks,
  without implementing those masks or script-specific stage ordering yet.
  Feature requests are parsed four-byte ASCII tags, sorted by all four bytes.
  Parsing shares a bounded reference-work capacity across the entire topology;
  planning checks its selected-reference cost before allocating edge arrays.
  Capacity failures are typed errors, not successful partial plans.
  The existing complete-selection entry point includes the required feature.
  A separate `ot_stage_plan_requested` entry point selects only requested
  features from LangSys.featureIndices; it does not automatically reinsert
  the required feature into every later script stage. A script scheduler still
  needs to assign required-feature execution to the appropriate stage once.
- Layout topology has 22 independently compiled ATS2 implementation modules.
  Tags, record arrays, headers, features, languages,
  scripts, lookup kinds/headers, selection, capacity accounting, feature-set
  ownership, plan selection/counts/fill/build and queries remain separate.
  All new buffer owners are linear; font-table bytes are borrowed, not copied.
- `data_font/gsub_single_*`: GSUB lookup type 1 SingleSubst formats 1/2 are
  payload-validated and queryable. Format 1 uses signed int16 deltas with
  modulo-65,536 arithmetic; format 2 indexes replacements by Coverage index.
  Both reject output glyph IDs outside the parent font's glyph domain. Format 2
  checks the exact Coverage/array count relationship. Covered range validation
  checks wrap crossings, not merely the two mapped endpoints; a covered wrap
  crosses glyph 65,535, which cannot exist with uint16 maxp.numGlyphs.
  Identity substitutions remain matches; an uncovered query leaves its input
  glyph unchanged. Numeric Unicode scalars/source offsets are not rewritten.
  Four implementation modules (at most 41 lines) separate delta validation,
  array validation, payload parsing and queries. Queries allocate no payload
  objects and borrow the immutable font bytes. The linear SingleSubst owner
  cannot be replaced by a phase-0 topology descriptor in the query API.
  This is one substitution primitive, not full GSUB or a complete run shaper.
- `data_font/gsub_sequence_*`: payload-validated GSUB type 2 multiple
  substitution and type 3 alternate sets, with borrowed ordered glyph views.
  Multiple sequences must be nonempty; duplicate output glyphs and glyph zero
  are retained. Alternate values are 1-based; zero disables selection, and an
  absent/out-of-range choice produces no substitution rather than silently
  selecting another glyph. Coverage/set count relationships and all output
  glyph domains are checked. Validation shares a bounded reference-work budget.
  Three small modules separate payload parsing, sequence validation and queries.
- `data_font/ot_layout_extension`: shared GSUB type 7 / GPOS type 9 extension
  format-1 headers, checked 32-bit target offsets, and domain-indexed target
  actions. Recursive extension kinds are rejected. A resolved target still
  needs its action-specific payload reader; common target-kind consistency
  across all subtables in an outer lookup remains a scheduler/ingestion task.
- `data_font/gsub_ligature_*`: GSUB type 4 payload validation and logical-order
  prefix matching. Component counts include the first Coverage glyph; one-
  component rules, empty rule sets, glyph zero and duplicate/shared rule data
  are supported. Rules are evaluated in the font's preference order, not sorted
  by length; the first complete match wins. Four independent modules separate
  record access, rules/sets validation, payload parsing and matching. The caller
  must supply lookup-context-filtered input; matching does not yet mutate a run,
  merge source clusters or assign skipped-mark ligature-component associations.
- `data_font/ot_cov_cache_*`: native, contiguous Coverage descriptor storage
  with a type-indexed initialized prefix. `OtCoverageCache(n,i)` cannot be
  queried until `i=n`; success exposes only a fully initialized cache. Native
  linear `arrayptr` ownership releases descriptor storage on every error and
  disposal path, without another `assume`. Only descriptors are stored; font
  Coverage bytes are borrowed, not cloned or reparsed during matching.
- `data_font/gsub_reverse_*`: GSUB type 8 reverse-chain format-1 payload
  validation and candidate matching. Backtrack Coverage entries follow reverse
  logical order (nearest preceding glyph first); lookahead follows forward
  logical order. Counts, replacements, all Coverage targets and glyph domains
  are checked. Type-indexed backtrack/lookahead counts agree with the owned
  descriptor-cache size. Four independently compiled modules separate header
  decoding, offset-field construction, Coverage ingestion and matching. A run
  scheduler still must apply candidates in end-to-start order.
- `data_font/ot_context_*`: shared GSUB 5/6 and GPOS 7/8 context payload
  readers and matchers for glyph, class and per-position Coverage encodings.
  Sixteen small modules separate headers, classes, rules, caches and matching.
  Backtrack order, nullable rule sets, class-zero behavior and font rule
  priority are preserved. Context Coverage/set count differences ignore
  unrepresented entries as specified, rather than rejecting valid tables.
  Ordered, repeated nested actions remain explicit; GSUB/GPOS action domains
  cannot be exchanged. Applying those actions to a changing run remains work
  for the lookup scheduler, not the context matcher.
- `data_font/gpos_value_*`, `gpos_adjustment_*`, `gpos_anchor_*`: shared GPOS
  ValueRecord and anchor readers. All eight optional value fields and all
  three anchor encodings are checked. Signed design units are separate from
  packed Device pixel adjustments; VariationIndex references retain their
  unresolved outer/inner indices. A contour anchor is a contour descriptor,
  not a falsely resolved point. Device offsets use the immediate parent
  table (including PairSet for PairPos format 1), not a fixed root offset.
  Native, initialized-prefix-indexed value caches own flat descriptors and
  release partial ingestions on failure without additional opaque assumptions.
- `data_font/gpos_single_*`: GPOS type 1 formats 1/2, with checked Coverage
  cardinality, no-op records, domain checks and cached allocation-free queries.
  Empty ValueRecords share one uniform descriptor, including 65,535 covered
  glyphs. Values are exposed to the future position accumulator; this is not
  yet a production positioning pass.
- `data_font/gpos_pair_*`: GPOS type 2 explicit-pair and class-matrix readers.
  PairSets validate sorted, unique second glyphs and immediate-parent Device
  offsets. Class zero is retained; class indices must fit their matrix.
  Values are cached at ingestion and queried by Coverage, class lookup or
  binary search. Present-zero value2 still advances past the pair; absent
  value2 continues at the second glyph. A zero-sized 65,535-by-65,535 class
  matrix remains a uniform no-op without multiplication overflow or billions
  of descriptors. Native linear PairSet and partial-value cache owners retain
  cleanup guarantees on malformed input. Accumulating these values into a
  glyph run remains a separate responsibility.
- `data_font/gpos_anchor_cache_*`, `gpos_anchor_slot_parse`: native flat anchor
  slots distinguish absent and present anchors. Required mark anchors and
  optional attachment points have separate presence contracts. Partial caches
  cannot be queried; negative compilation tests enforce initialized-prefix
  ownership for both anchor and ValueRecord caches.
- `data_font/gpos_cursive_*`: GPOS type 3 Coverage/entry/exit validation and
  cached logical-pair matching. Either missing attachment point means no
  attachment. Font coordinate, contour and Device/Variation anchor descriptors
  stay explicit. Three small modules separate offset fields, ingestion and
  queries; RTL cross-stream adjustment and attachment-chain propagation belong
  to the future position accumulator.
- `data_font/gpos_mark_matrix_*`: shared, domain-indexed GPOS type 4
  mark-to-base and type 6 mark-to-mark payload readers and anchor matching.
  Separate mark/target Coverage and array cardinalities, mark class domains,
  mandatory mark anchors and optional target anchors are checked at ingestion.
  Shared mark parsing separates headers, record validation, offset fields and
  anchor ingestion from four matrix-specific modules. A native cached class matrix
  supports 65,535 classes without query-time table parsing or allocation.
  MarkArray and BaseArray/Mark2Array offsets retain their correct parent bases.
  Choosing the preceding attachment glyph and accumulating mark displacement
  remains the run scheduler/position accumulator's responsibility.
- `data_font/gpos_mark_shared_*`: five shared modules now own the root headers,
  MarkArray class validation, offset-field construction and anchor ingestion
  for GPOS types 4/5/6. The former matrix-only fields/records files were moved
  into this common responsibility instead of duplicated for ligatures.
- `data_font/gpos_mark_ligature_*`: GPOS type 5 payload validation and cached
  mark-to-ligature anchor selection. Six modules separate native group storage,
  LigatureArray/LigatureAttach validation, partial-anchor ingestion, orchestration
  and queries. A zero-based component is selected explicitly in logical order;
  the reader does not guess a last component or reverse it for RTL. Missing
  attachment points and empty component arrays produce no attachment. Native
  group/anchor owners retain cleanup on all error paths. Both group descriptors
  and their fully initialized anchor matrix stay cached, rather than parsing
  the font at each query. Source-run associations choose the component later.
- `data_font/glyph_run_*`: source-mapped native glyph-run storage with stable
  node IDs and separate contiguous core, link and position columns. Twenty
  small modules (at most 40 lines each) separate storage, lifetime, checks,
  links, single/multiple edits, ordered ligature merging, association resolution,
  position validation and queries. Nominal, substitution, positioning and frozen
  phases are distinct indexed linear types. Rejected edits return the unchanged
  owner; domains, source spans, selection order and capacity are checked before
  mutation. Multiple substitutions retain original byte spans and clusters;
  ligatures preserve ignored nodes and forward nested owner associations.
  Ligature formation now merges clusters across the complete matched interval,
  including ignored marks, while preserving each mark's original byte span.
  Position attachments reject cycles. Source spans, zero advances and glyph
  zero stay explicit. Queries allocate no payloads; the public edit wrappers
  are linear owned results, not a claim of allocation-free hot-pass execution.
  The storage/edit kernel is implemented; font-aware lookup traversal, feature
  masks, contextual action execution and attachment offset accumulation are
  still required before this is a complete shaper or renderer snapshot.
  Expanding an already formed ligature also still needs shaping-level class
  overrides and component-association reassignment; cloning stored rows alone
  does not establish correct general ligature/multiple interaction.
- `data_font/glyph_pass_*`: the first executable primitive pass applies one
  payload-validated GSUB SingleSubst to a substitution-phase run. Three small
  modules (10–29 lines) separate mask selection, borrowed-storage traversal
  and ownership handoff. The run is unpacked once, rather than reboxing a
  public edit result for each glyph. The inner loop allocates no payloads.
  It follows live logical links, including appended IDs and gaps left by
  ligatures, preserves source spans/clusters/associations and never treats
  glyph zero as a missing match. Identity substitutions still count as matches.
  A different glyph domain rejects the whole pass before mutation. Typed
  all-glyph versus bit-mask selection keeps feature eligibility explicit.
  This primitive does not schedule outer lookup/subtable priority, build GDEF
  eligibility, verify parent-font identity, or implement Arabic script stages;
  callers retain the immutable font bytes used to parse the primitive.
- `data_font/ot_single_lookup_*`: six small modules cache all
  payload-validated GSUB SingleSubst descriptors of one direct or extended
  lookup in a native contiguous array. Header parsing, native storage,
  extension dispatch, linear prefix ingestion, orchestration and scalar
  queries are separate. A partial `OtSingleTables(n,i)` cannot be queried
  until `i=n`; rejecting a later subtable releases the partial owner. Queries
  try subtables in font order and stop at the first coverage match, including
  identity substitutions and replacements with glyph zero. They do not apply
  successive subtables to their own outputs. Descriptors retain borrowed font
  spans; no font-table bytes are copied or reparsed at query time. Lookup flags
  and mark-set indices remain metadata for future GDEF-aware traversal, not
  evidence that scalar queries implement filtering or full run execution.
- `data_font/glyph_metadata_*`: six small modules (11–32 lines) parse GDEF
  classes/attachments/mark sets, fill a native per-glyph property cache and
  filter glyphs. Partial native rows cannot be queried. Missing GDEF stays
  explicitly unclassified; no Unicode class guesses are silently introduced.
  Class and attachment queries are constant-time; mark-set membership uses
  the existing borrowed Coverage descriptors. Metadata owns its derived rows
  and mark-set descriptors, not the immutable parent font bytes.
- `data_font/glyph_pass_lookup*`: a cached SingleSubst lookup now executes on
  the live run with feature masks, current-glyph GDEF filtering and first-subtable
  priority. Three modules (20–33 lines) separate preflight, borrowed traversal
  and ownership handoff. Font ID, glyph-domain, required GDEF references and a
  conservative candidate-work budget are checked before mutation; rejection
  returns the unchanged owner. The current glyph ID is reclassified on every
  later lookup, so substitution cannot leave stale input-class filtering.
  Font ID checks do not independently prove parent-byte identity; callers must
  still retain the same immutable font for metadata and lookup descriptors.
- `data_font/ot_sequence_lookup_*`: six small modules (13–33 lines) cache
  direct/extended GSUB 2/3 descriptors with kind-indexed linear owners and
  fully initialized native prefix arrays. The shared GSUB/GPOS header reader
  also serves SingleSubst. Ingestion shares one work budget across the complete
  lookup, including repeated subtable offsets. Multiple queries stop at the
  first match; alternate queries stop at the first actual requested selection,
  allowing an earlier empty/short set to decline a choice. Identity outputs
  and glyph zero remain matches. No payload is reboxed in these queries.
- `data_font/glyph_pass_multiple*`, `glyph_pass_alternate*` and
  `glyph_expansion_*`: native GSUB 2/3 run execution uses feature masks and
  current-glyph GDEF filtering. A common preflight checks font/glyph domains,
  GDEF dependencies and conservative candidate work. Multiple substitution
  first builds an immutable native expansion plan, checking total storage and
  association support before any mutation. It reserves once and reads ordered
  outputs directly from validated font spans, without temporary output buffers
  or per-glyph public edit wrappers. Only original live nodes are visited by
  that lookup; inserted outputs cannot recursively feed it. Original scalar,
  byte span, grapheme cluster and mask survive expansion, including sparse IDs.
  Expanding an already associated node with more than one output explicitly
  returns `GlyphPassReference` and the unchanged owner: general multiplication/
  ligature affinity and class overrides are still required. A one-output
  sequence preserves its existing association as a single replacement.
- `data_font/glyph_nominal*`: three small modules connect strict UTF-8 scalar
  text, the Unicode 18 grapheme state machine and an immutable SFNT face to a
  nominal native glyph run. Metadata, allocation/orchestration and native row
  filling are separate. Source bytes/scalars remain unchanged; cluster IDs
  are original byte starts of extended grapheme clusters, including combining
  Turkish letters and Arabic marks. Missing cmap entries retain glyph zero.
  Filling unpacks storage once and allocates no per-scalar payload/edit result.
  This does not normalize, choose fallback fonts, itemize scripts, position
  glyphs or build a production layout snapshot.
- `data_font/glyph_neighbor*`: three small modules provide allocation-free
  logical forward/backward neighbour queries over live links, skipping glyphs
  through GDEF rules without copying a document suffix. The initial node is
  already selected by outer traversal; only neighbours are filtered. Indexed
  gaps, inserted node IDs and mark-set precedence remain explicit. Direction is
  a typed traversal choice, never inferred from a lookup's RightToLeft bit.
  Input-feature eligibility and script-specific default-ignorable/ZWJ policies
  still need their separate matcher layer.
- `data_text/arabic_join_*` and `data_font/glyph_arabic_*`: seven small modules
  implement basic Arabic joining form masks from the pinned Unicode 18
  Joining_Type map, independently of the old Presentation Forms renderer.
  The logical-order state machine implements the connectivity rules in
  [Unicode 18 Arabic cursive joining](https://www.unicode.org/versions/Unicode18.0.0/core-spec/chapter-9/).
  Transparent marks retain neighbouring connections; ZWJ/join-causing and
  ZWNJ/non-joining scalars are distinct. Typed boundary context preserves
  joining across itemization/font splits and excludes transparent neighbours.
  Mask plans reject overlapping or multi-bit form masks; zero disables an
  unavailable feature. Preparing a nominal run preserves scalar values, glyph
  IDs, source spans and unrelated feature bits, then seals it as a substitution
  run. No presentation-form scalar substitution is performed. Syriac joining
  groups, script-stage scheduling, complete GSUB execution, default
  ignorable removal and GPOS positioning are not supplied by this preparation.

The production font loader now uses the SFNT module for character mapping and
advances. It validates a new file before replacing the active face, so a failed
load preserves the previous face and cache. Arabic fallback file storage is
owned by each `Font` through a linear optional buffer; the global C buffer and
global read-switch were removed. `font_use_fallback_file` also permits explicit,
validated fallback selection without depending on a global discovery result.
Compound rendering aligns child contour
points to previously incorporated parent contour points. Rasterization no
longer substitutes bitmap width for a font's zero advance.

New algorithms are ATS2. There are no new `assume`, unsafe casts, algorithmic C
implementations, or HarfBuzz/FreeType runtime dependencies. Font discovery
remains an OS adapter. The airlock also rejects an overflowing signed span
before asserting its natural-number result.

The former 1,906-line `font.dats` is now split into 23 separately compiled
modules: ownership/storage, face loading, metrics, numeric operations, simple
and compound outlines, curve geometry, scanline coverage, bitmap fallback,
TrueType rasterization, cache, atlas, dispatch, legacy kerning, discovery and
selftests. Private `.sats` contracts expose only the operations needed across
these responsibilities. The owner is 618 lines; computation modules are at
most 219 lines. Numeric storage-field selectors were removed in favor of
direct typed field access, including `Toggle` for font availability.

The separate `font_glyph_id` API rasterizes an explicit primary/fallback glyph
ID directly, including the selected face's real glyph-zero `.notdef`; it never
reinterprets a shaped glyph ID as Unicode or applies legacy character kerning.
Unavailable faces and out-of-domain IDs are typed rejections with empty output
metrics. Cache keys distinguish Unicode codepoints, primary glyph IDs and
fallback glyph IDs, plus ppem; the Font owner supplies face identity and face
replacement invalidates entries. Cached fallback requests do not swap source
owners. Cache key encoding, entries, probing and orchestration are separate.
Atlas packing planning is separate from state/resource changes. Atlas overflow
now flushes pending render batches before deleting their texture, rather than
waiting until a later upload. Callers still keep face and size fixed while
using atlas coordinates; a general immutable atlas/layout lease is not supplied
by this API. Production character drawing has not switched to this entry point.

Build configuration is separated as well: the 130-line root CMake file owns
the application build, while Unicode data generation, text/BiDi conformance,
font tests/probing and airlock tests live in dedicated `cmake/` modules.
Shared ATS source generation now has a single dependency target. Executable
consumers wait for it, preventing parallel Make dependency graphs from writing
the same generated C file while another target compiles that file.

## Verification

Build and run the CPU tests:

```sh
cmake -S . -B build
cmake --build build --target utf8_conformance gsub_single_conformance gsub_sequence_conformance gsub_ligature_conformance gsub_reverse_conformance ot_context_conformance gpos_value_conformance gpos_single_conformance gpos_pair_conformance gpos_cursive_conformance gpos_mark_matrix_conformance ot_layout_conformance opentype_conformance gdef_conformance line_conformance line_contracts normalization_conformance normalization_contracts text_conformance word_conformance bidi_core_conformance bidi_character_conformance bidi_class_conformance bidi_document_conformance unicode_contracts sfnt_conformance component_conformance airlock_conformance
ctest --test-dir build --output-on-failure
```

Tests cover invalid and truncated UTF-8, source byte ranges including NUL and
replacement characters, 32,768 decoded scalars in a 64 KiB mixed Turkish/Arabic
buffer, and resource disposal. Font tests cover missing mappings, zero advances,
shared trailing advances, negative bearings, corrupt/overlapping tables, every
truncation of a synthetic font, glyph-array cmap mappings, unsigned component
arguments, offset scaling, matrix orientation, and malformed components.
Dedicated UTF-8 tests encode/decode every 1,112,064 Unicode scalar, test all
single-byte inputs and invalid spans, and check exact retained storage for a
mixed Turkish/Arabic/combining/emoji/NUL/malformed sequence. The latter retains
84 bytes for seven output scalars rather than the previous 180 bytes for 15
source bytes. A separate generated-layout contract rejects boxed/payload
construction in the UTF-8 step implementation, beyond buffer-only accounting.
Airlock tests cover representable signed spans and require the overflow case
to terminate with its specific airlock diagnostic. Production DATS generation
also has an explicit `patsopt -tc` gate before emitting C.
Unicode contract tests reject all truncated headers, wrong property domains,
invalid property values/ranges and wrong data versions. A negative compilation
test verifies that a `PropertyMap(2)` cannot be passed to the word-boundary API
requiring `PropertyMap(1)`. Mirror tests exercise every loaded mapping at odd
and even levels, including supplementary codepoints and non-mirroring ornate
Arabic parentheses.
Normalization contract tests cover source ranges after Turkish composition,
Arabic mark reordering, Hangul composition and canonical decomposition, plus
an uninterrupted 32,768-mark combining sequence. They reject every truncated
asset length, malformed headers/rows/mappings, cyclic dependency data and
expansion overflow. A negative compiler test rejects composing unordered text.
The reference specification is [UAX #15](https://www.unicode.org/reports/tr15/);
the conformance inputs remain the pinned official Unicode 18 files.
Line contracts separately assert mandatory CRLF/LF/VT/NEL/LS/PS boundaries,
empty input, nonbreaking spaces/joiners, Turkish and Arabic combining marks,
emoji ZWJ sequences and flag parity. Stress tests cover uninterrupted sequences
of 32,768 marks, spaces and regional indicators. A negative compiler test
rejects a word property map where a line property map is required. The line
reference is [UAX #14](https://www.unicode.org/reports/tr14/).
OpenType tests query all 65,536 glyph IDs plus outside-domain sentinels,
including full-range coverage and the maximum 65,535-entry lists/range tables.
Device tests compare 917,504 deltas against an independent unsigned-bit oracle.
Tests reject every truncation of representative tables, bad ordering/coverage
indices, invalid domains, malformed padding and overflowing/out-of-table offsets.
All 65,536 lookup-flag words are checked; the 8,192 legal combinations are also
tested against all five GDEF classes and matching/mismatching mark filters.
GDEF tests cover all header versions, absent data, invalid classes, overlapping
mark sets, malformed 32-bit offsets, truncation and buffer disposal.
A negative compiler test rejects exchanging Coverage and ClassDef descriptors
or treating a parsed Device/VariationIndex result as a pixel-device descriptor.
References are the [OpenType common formats](https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2)
and [GDEF specification](https://learn.microsoft.com/en-us/typography/opentype/spec/gdef).

The optional GDEF font test can be enabled with the CMake FILEPATH settings
`ANTHRACITE_OT_LATIN_TTF` (DejaVu Sans Mono) and `ANTHRACITE_OT_ARABIC_TTF`
(static Noto Naskh Arabic). The tested fonts give Latin a/acute glyph IDs
68/649 and GDEF classes 1/3; Arabic beh/fatha give IDs 614/378 and classes 0/3.
The Arabic nominal beh really is unclassified in this font's GDEF; this was
independently checked from its raw table, rather than weakening the reader.
Its nominal glyph IDs also match `hb-shape --shapers=fallback`.

Layout topology tests reject every truncation of the representative graph,
bad offsets, ordering, references, header versions and missing GDEF capabilities.
They exercise named-only scripts, missing DFLT, shared Script tables, mandatory
features, duplicated feature tags/references, shared lookup provenance, and
out-of-document language spans. Capacity tests verify exact limits, shared
accounting and typed rejection. Stress cases include 65,535-entry LangSys and
Feature lookup-index arrays and 65,535 feature-request tags.

The optional layout font test uses the same two CMake font paths. Its oracle
compares every selected lookup ID and contributing feature ID, independently
decoded from the raw tables; it does not compare shaped glyph output. Requested
features are `ccmp liga rlig calt init medi fina isol kern mark mkmk`, for the
default `latn`/`arab` language. The known fonts yield GSUB/GPOS plan sizes 1/2
(Latin) and 16/24 (Arabic), including a shared Arabic GSUB lookup owned by two
features. The reference files have these SHA-256 hashes:

```text
DejaVuSansMono.ttf         9d9bfebceb1c3f6f4ad383ded568a6926086208f43f7f92f92f7e93a1383fa38
NotoNaskhArabic-Regular.ttf 2d5d78e9cc27d7193926c7e460314c9da7dbec1268494dbf117adc53c171ac06
```

Different font versions can legitimately have different topology and therefore
do not share this fixed oracle. These external test fonts are not yet pinned
redistributable production assets.

SingleSubst tests cover both substitution and Coverage encodings, identity,
glyph zero, signed limits, valid modular wrapping, invalid wrapped ranges,
Coverage-count mismatches, and exact error reasons/offsets. They reject every
truncation of representative payloads. Stress tests check all 65,536 raw delta
words, 131,076 boundary/glyph queries, and the largest format-2 replacement
array whose trailing Coverage offset fits uint16 (32,764 entries).
The optional SingleSubst font test uses the same pinned fonts above and checks
first/middle/last coverage entries of all direct type-1 lookups: 16 Latin and
60 Arabic samples across 7/25 lookups. Expected mappings were independently
decoded from raw font bytes, not generated by the native query code. These
samples validate individual payloads, not their feature masks or application
to an Arabic word. Reference: [OpenType GSUB SingleSubst](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub#lookup-type-1-subtable-single-substitution).

The optional `font_probe` target reports base glyph IDs and unscaled metrics.
Its Noto Naskh Arabic results for U+0628, U+064E, U+064F, U+FD3E and U+FD3F
match `hb-shape --shapers=fallback --no-glyph-names` on the same font. This
comparison validates base mapping/metrics, not contextual shaping.

The optional `font_render_conformance` target requires an X11/GLX display and
these arguments:

```text
font_render_conformance NEW_FIXTURE_PATH NEW_INVALID_PATH LATIN_TTF ARABIC_TTF
```

Use new paths in an isolated temporary directory: the first two files are
written by the test. The Arabic test font must cover beh, fatha and the ornate
parentheses, with zero fatha advance (Noto Naskh Arabic was used). Tests exercise
actual component rasterization, zero mark advance, failed-load preservation,
face isolation, and balanced buffer ownership. They pass on isolated Xvfb.
The production `anthracite --selftest` also passes there, including
`font_selftest=1`, `doc_selftest=1`, `img_selftest=1`, `app_selftest=1` and
the repository invariant `live=1530113`.
After the line-breaking stage, all 18 registered CPU/type-boundary tests pass.
The Xvfb raster tests and all four production selftests also pass, still with
exactly `live=1530113`. These regressions do not establish production OpenType
shaping correctness; that integration remains below.
After the common OpenType/GDEF stage, all 21 mandatory CPU/type tests pass,
as does the configured optional font test (22 tests total). Raster and all four
production selftests still pass on Xvfb with `live=1530113`.
After layout topology/planning, all 23 mandatory CPU/type tests and both
configured optional font tests pass (25 tests total). All new layout cases
report zero errors and balanced buffer ownership. The Xvfb outline/mark/face
isolation tests and all four production selftests also pass, with unchanged
`live=1530113`. These results still do not establish production shaping or
pixel-width wrapping correctness.
After UTF-8 storage/flat-step changes and the SingleSubst primitive, all 27
mandatory CPU/type/layout tests and three configured optional font tests pass
(30 tests total). The complete suite takes about 2.7 seconds in this environment.
UTF-8 and SingleSubst reports have zero errors and balanced buffer ownership.
Xvfb raster tests and all four production selftests still pass, with unchanged
`live=1530113`. These checks do not imply that the production renderer now
uses the new decoder or applies GSUB/GPOS shaping.

The next primitive stages add Multiple/Alternate/Ligature/Reverse substitution,
shared six-format GSUB/GPOS context matching, ValueRecord/anchor readers, and
GPOS SinglePos, PairPos, CursivePos and MarkBase/MarkMark readers. Tests cover
arbitrary ordered context actions, no-op matching, malformed offsets, every
representative truncation, maximum component/array counts, 65,535 classes,
pair continuation rules and correct per-parent Device offsets. Negative
compilation rejects partially initialized Coverage, ValueRecord and anchor
caches, as well as exchanging GSUB/GPOS context action domains.
Optional font oracles check ordered Noto substitutions, ligature outputs,
DejaVu Sans Mono SinglePos adjustments and ten Latin/Arabic mark-anchor pairs.
The optional PairPos oracle uses `ANTHRACITE_OT_KERN_TTF` pointing to static
DejaVu Sans, whose SHA-256 here is
`58568c88a01b80dfc056daca3eeafd434a0380df1a48dda53f0de0d716109bbd`.
It checks AV, To, Wa and AA pairs against independently decoded font values.
These files remain external test assets, not pinned production font resources.
At the earlier mark-matrix checkpoint, all 48 registered CPU/type/font tests passed after
a full rebuild (about 3.5 seconds here). Fresh Xvfb raster checks report zero
outline, mark, face-isolation and buffer-ownership errors. The four production
selftests remain successful with `live=1530113` (`start_ms=48`, `rss_kb=106496`
in this run). Native descriptor allocation ownership is enforced by ATS linear
types and negative compiler tests; `mem_live()` accounts for owned `Buf` payloads,
not the separate native `arrayptr` descriptor allocations. These checks do not
establish completed run shaping or production mixed-script rendering.

The subsequent lookup/run checkpoint (2026-10-13) has 56 registered tests,
all passing after a full rebuild. MarkLigature, source-mapped run edits,
extension target-kind consistency and requested-only stage selection are
covered. The executable SingleSubst pass checks 32,768 live nodes, source
range preservation, selective/disabled masks, domain rejection, identity and
glyph-zero replacements, and noncontiguous IDs after multiple/ligature edits.
Cached SingleSubst lookups check first-subtable priority, direct/extended
payloads, partial-ingestion cleanup, malformed later subtables, mark-set header
metadata and 32,764 aliased subtables. Negative compilation rejects queries
on a partial native table cache and substitution passes on frozen runs. Both
the primitive pass and cached candidate lookup match 76 existing independent
Latin/Arabic font oracle rows (16 Latin and 60 Arabic); this is not a complete
word-shaping comparison with HarfBuzz. Fresh Xvfb raster checks have zero
outline/mark/face-isolation/buffer errors. All four production selftests pass
with `live=1530113` (`start_ms=47`, `rss_kb=106208` in this run). Native array
ownership is checked by ATS linear types, not included in the `mem_live()`
buffer counter. These passing regressions do not establish that the production
renderer has switched to the new shaping pipeline.

The GDEF/joining/neighbour checkpoint (2026-10-13) passes all 58 registered
tests after rebuilding every CPU/font target and the application. Cached
SingleSubst execution, including current-glyph GDEF filtering and feature
masks, matches the same 76 independent Latin/Arabic oracle rows. Synthetic
tests cover mark-set/attachment precedence, reclassification after substitution,
unchanged-owner rejection for bad font IDs/domains/references/work capacity,
and 65,535 cached glyph properties. Logical neighbour tests cover both
directions, ignored current nodes, inserted IDs, removed nodes, positioning
runs and 32,768-node mark-heavy walks. Arabic joining tests check all 216
three-type combinations against an independent connectivity model, Turkish/
Arabic UTF-8 source preservation, ZWJ/ZWNJ/tatweel, transparent marks, typed
external context, Unicode 18 left-joining crown letters and a 32,768-scalar
mark-heavy run. Negative compilation rejects late joining preparation, wrong
property domains and partial glyph-property caches. Ligature tests also check
cluster merging across ignored marks without rewriting their source spans.
Fresh Xvfb raster checks have zero errors; the four production selftests pass
with `live=1530113` (`start_ms=47`, `rss_kb=106356` here). These results verify
the kernel layers, not a completed production renderer migration.

### Native GSUB/nominal/glyph-ID checkpoint (2026-10-13)

All 60 registered tests pass after rebuilding the application and every CPU/
font target. Cached GSUB 2/3 execution checks ordered direct/extended subtables,
empty/short alternate-set priority, glyph zero/identity, feature masks, GDEF
filter precedence, sparse IDs, repeated passes and atomic rejection. A
32,768-node input expands to 98,304 nodes with preserved source data; huge
candidate/output capacities are rejected before mutation. Seven existing
independent Noto oracle rows now also exercise complete cached lookups and run
execution, including both choices of the alternate row. Negative compilation
rejects partial descriptor/expansion caches, wrong lookup kinds and wrong phases.

The native nominal builder passes mixed Turkish/Arabic/decomposed source tests,
malformed UTF-8/NUL and empty input, and 32,768-scalar font-backed stress cases.
An explicitly selected Noto `ccmp`/`fina`/`init` test for `بَب` produces logical
glyph IDs `[19,321,378,15,321]` with byte clusters `[0,0,0,4,4]`. These match the
reversed logical view of an independent HarfBuzz 13.2.1 OpenType result using
`--utf8-clusters --direction=rtl --script=arab --language=ar`. This narrow
substitution comparison does not test GPOS offsets, visual BiDi ordering or a
general script-feature scheduler; the test does not call HarfBuzz at runtime.

The original mixed-language note is read-only checked with both test faces:
4,198 scalars, 3,777 extended grapheme clusters, no malformed UTF-8 and no
source-span errors. Nominal glyph-zero counts are 16 for DejaVu Sans Mono and
2,492 for Noto Naskh Arabic; these include controls and are not a claim about
visible missing characters or completed fallback. To repeat this optional
diagnostic without writing the note:

```text
build/glyph_pass_conformance LATIN_TTF ARABIC_TTF build/unicode18.bin build/unicode18-joining.bin NOTE_MD
```

Fresh isolated Xvfb checks report zero primary/fallback glyph-ID, domain,
cache and atlas errors. They compare nominal versus direct-ID raster metrics
at 16/24/48 ppem, same-ID face isolation, glyph zero, empty glyphs, the last
valid ID versus `numGlyphs`, cache kind/ppem collisions and bounded eviction.
Empty TrueType outlines now have zero ink bearings rather than borrowing font
ascent. The atlas test first proves that its reference contains real ink, then
compares framebuffer bytes after a forced overflow with a still-pending glyph
quad; this catches deleting the old texture before flushing its batch.
All four production selftests pass with unchanged `live=1530113`
(`start_ms=47`, `rss_kb=106380` in this run). This remains a kernel/raster API
checkpoint, not a completed production text-renderer migration.

Validation logs: `/tmp/anthracite-nominal-id-final-build.log`,
`/tmp/anthracite-nominal-id-final-ctest.log`, and
`/tmp/anthracite-nominal-id-xvfb.sSRFEV/`.

### Earlier native positioning/context checkpoint (2026-10-14)

The application and every CPU/font target have been rebuilt; all 66 registered
tests pass. Native 26.6 GPOS 1–6 execution, attachment reconciliation and the
frozen glyph-run GPU API are implemented. Font-scoped `ot_position_graph_*`
caches now validate and own GPOS 7/8 contextual programs, including uniform
type-9 extensions and action references into the complete LookupList.
`glyph_position_lookup_graph_*` executes nested actions with an explicit,
geometrically growing native frame stack. It restores cache-cell loans before
following an action, detects active `(lookup,node)` cycles and rolls back the
entire lookup/stage on a reference, capacity or coordinate failure.

The lookup graph and the mark/cursive attachment graph have separate interfaces
and implementations. A per-pass GDEF-filtered rank map resolves contextual
action positions without repeatedly scanning the input. Reusable context
windows apply feature masks/ligature affinity only to the input prefix;
backtrack/lookahead retain their real glyphs. Each subtable keeps its own
input/look boundary even when it borrows a larger shared window.

The positioning stage uses this complete font-scoped cache and one transactional
position column for all selected lookups. Tests cover all six context encodings,
extension contexts, nested lookup ordering/continuation, matched no-op priority,
sparse IDs, GDEF-skipped marks, late overflow rollback, cyclic references and a
2,048-level nested lookup chain. Negative compilation rejects partial graph
caches and applying a lookup graph to frozen positions.

Actual Noto `mark/mkmk` stages still match the independent HarfBuzz 13.2.1
`بَب` offsets/advances at 16/24/48/1,000 ppem, including all 24 selected lookups.
The tests do not link to HarfBuzz. NFC provenance and reordered source spans are
also preserved through the nominal builder and positioning tests.

Font-aware GSUB 4 primitive/cached lookup execution now merges source clusters
and preserves skipped-mark, nested-ligature and multiple-component associations.
Seven independent Latin/Noto ligature oracle rows pass through complete cached
lookups and run mutation. GSUB 5/6 nested mutation and type-8 run traversal are
still pending; their payload readers/matchers are not production execution.

Fresh isolated Xvfb checks report zero direct-ID, frozen-run raster, fallback,
cache, atlas and buffer errors. The four production selftests pass with
`live=1530113` (`start_ms=46`, `rss_kb=106296`). This counter covers owned `Buf`
storage, not every native array or ATS owner allocation. Production drawing
still uses the old wrappers, so these results do not claim that the reported
mixed-language rendering problem is fully fixed.

Validation logs: `/tmp/anthracite-context-checkpoint-build.log`,
`/tmp/anthracite-context-checkpoint-ctest.log`, and
`/tmp/anthracite-context-xvfb.ipT9Ck/`.

### Native script/shaping checkpoint (2026-10-14)

The application and all CPU/font targets were rebuilt from the current
interfaces. All 75 registered tests pass. Logs:
`/tmp/anthracite-native-final-build.log` and
`/tmp/anthracite-native-final-tests.log`.

- Complete native GSUB 1–8 graph execution now includes reverse traversal,
  nested context mutation and whole-stage rollback. The previous checkpoint's
  pending GSUB 5/6/8 execution is implemented, not still pending.
- Unicode 18 Script, Script_Extensions and Default_Ignorable_Code_Point assets
  are compiled in ATS2. Script itemization intersects extension sets, respects
  grapheme bases, retains paired-punctuation context and resets at paragraph
  boundaries. Tests include every official script/extension row and deeply
  nested/nonmatching bracket stress cases.
- Source-derived fallback glyph classes are separate from actual GDEF classes.
  Without GDEF, non-ignorable Mn scalars supply mark hints; Mc/Me and default
  ignorables do not become guessed marks. Actual GDEF classes always take
  precedence, including class zero. Per-source hints survive substitution;
  ligatures acquire ligature hints and multi-output splits become bases.
- `ot_shape_*` compiles horizontal common/Arabic schedules from Script/LangSys
  feature records. It keeps lookup order within each stage, merges shared
  lookup selections and assigns the required feature to one stage only.
  Basic Arabic isol/fina/medi/init are separate masked stages. GPOS uses the
  shared schedule model. This is not a universal complex-script shaper.
- `glyph_substitution_schedule_*` and `glyph_position_schedule_*` borrow one
  font-scoped graph. GSUB uses one scratch run/workspace for the whole script
  schedule; GPOS uses one transactional position workspace. No font bytes or
  complete graph are copied per stage or lookup.
- `native_shape_*` separates cache ingestion, plan ownership, render-text
  preparation, joining, substitution, positioning and frozen-run completion.
  Owner bridges borrow validated face bytes directly. Prepared render text is
  a distinct linear input type, so raw ScalarText cannot accidentally bypass
  its preparation API. Exact face-byte lifetime/identity is still the caller's
  responsibility; generation-safe production font ownership is not implemented.
- `data_text/arabic_marks_*` implements Unicode 18
  [UAX #53 AMTRA](https://www.unicode.org/reports/tr53/): source-mapped NFD,
  stable mark promotion and CGJ/nonstarter boundaries. Modifier marks come
  from the unchanged pinned PropList, not a handwritten character list.
  Its property asset is independently checked across all 1,114,112 scalars;
  mark/source-span cases and 32,768-mark stress pass.
- Arabic prepared text uses AMTRA and optionally recomposes only adjacent
  starter/mark prefixes whose resulting glyph exists in the selected face.
  It does not skip intervening marks or rewrite document bytes. Common text
  uses the source-mapped NFC view. Mark advances are cleared after GPOS;
  surviving default ignorables retain source nodes but have zero advances and
  are not rasterized. Joiner/default-ignorable pattern-matching policy is still
  pending and must not be confused with this final visibility policy.
- Actual Noto Arabic schedules match independent HarfBuzz 13.2.1 glyph oracles
  for `بَب`, `سلام`, `الله`. Positioning schedules preserve the established
  16/24/48/1,000-ppem mark oracles. The combined prepared-text-to-frozen-run
  facade matches Turkish `Ş İ`, zero-width ZWJ, and canonically equivalent
  `بَّ`/`بَّ` glyph/position rows. Tests do not link to HarfBuzz.
- `native_shape_script` translates supported resolved Unicode scripts to
  OpenType requests. Latin/Greek/Cyrillic use the common profile; Arabic uses
  its own profile. Common/Inherited/Unknown use DFLT. Other complex scripts
  return an explicit unsupported request, not a guessed common shaper.
- `native_text_assets_*` is the filesystem/ownership shell. It loads grapheme,
  category, ignorable, joining, normalization, modifier-mark, script/extension,
  BiDi, bracket/mirror, word, line and width data once. It is separate from
  layout and drawing; a late load failure disposes all earlier owners.
  Success and early/late missing-resource tests check balanced Buf ownership.
- `native_text_analysis_*` is a pure paragraph facade. It produces one owned
  source-mapped NFC view with BiDi levels, script items, grapheme boundaries
  and legal line-break opportunities. Mixed Turkish/Arabic, normalization
  provenance, empty text and invalid source spans pass. It does not choose
  fonts, execute shaping, calculate pixel wraps or mutate AST coordinates.
- CMake now rejects production module names that collide with test/tool
  generated C outputs. Production shape-data disposal and test data loading
  have distinct generated modules.

These are executable CPU shaping and GPU-run APIs, not a completed production
editor migration. `font_draw_buf` still enters the old drawing wrappers.

Fresh isolated Xvfb validation passed direct-ID, frozen-run, fallback, cache,
atlas and owned-buffer checks. All four production selftests passed with
`live=1530113` (`start_ms=46`, `rss_kb=107192`). GPU/selftest logs:
`/tmp/anthracite-native-final-xvfb.iuLeZh/`. The counter measures Buf ownership,
not every native array or ATS allocation. These tests do not establish that
production drawing has adopted the new shaping facade.

## Logical itemization checkpoint (2026-10-14)

`native_text_items_*` now connects paragraph analysis to explicit logical
shaping partitions. Boundary discovery, source-span aggregation, traversal
and linear array ownership have separate ATS2 modules. The two-pass builder
does not copy text or reread files. It groups complete extended grapheme
clusters by resolved script and embedding level, separating paragraphs even
when their script/direction match. CRLF and emoji ZWJ clusters stay intact;
marks inherit their cluster's leading scalar level. Original byte envelopes
are computed from all member spans, not assumed monotonic after normalization.

The analysis conformance test now checks empty input, Turkish/Arabic,
source-mapped NFC, CRLF, cross-script marks, directional isolates, emoji ZWJ,
canonical mark reordering and 65,536 alternating-script items. Coverage,
cluster-edge keys and source envelopes are checked for every item. Main
application and analysis targets rebuilt; all 75 registered tests passed.
Isolated Xvfb production selftests passed with `live=1530113`
(`start_ms=41`, `rss_kb=106260`). Logs:
`/tmp/anthracite-items-tests.log`, `/tmp/anthracite-items-xvfb.Qv3cT6/`.
This Buf counter does not measure every native array/ATS allocation.

These are logical item ranges, **not** selected fonts, pixel wraps or visual
glyph order. The following checkpoint adds external Arabic context and the
one-face shaping bridge. Production font-cascade refinement remains required.
Production drawing remains on the legacy path; this checkpoint does not
claim the reported display defect is fixed.

## Paragraph-to-shaping checkpoint (2026-10-14)

`normalization_apply_range`, `arabic_marks_apply_range` and
`native_shape_text_parse_range` process half-open scalar ranges directly from
a borrowed paragraph view. They allocate the necessary normalization/shaping
output, not an intermediate scalar copy or another UTF-8 decode. Invalid ranges
return typed errors; original byte provenance survives. The source's aggregate
decode-error count is retained, not misrepresented as a range-specific count.

`native_text_context_*` stores nearest non-transparent Arabic neighbours at
every scalar boundary in two linear passes. Paragraphs reset context; CRLF,
marks, ZWNJ, ZWJ and empty input have tests. `native_text_shape_*` composes the
resolved script/direction, selected face/cache, range preparation and context
into a frozen GSUB/GPOS run. Planning, preparation and execution errors remain
distinct. Face selection, visual order, pixel wrapping and drawing are outside
this bridge. The Noto middle-cluster test preserves its medial glyph (16) and
299/64-pixel advance instead of shaping it as an isolated word fragment.

`native_text_coverage` tests all required scalars of a **whole** cluster against
one face before trying the alternative. Missing marks reject that entire face;
default ignorables stay in the shaping input without requiring cmap coverage.
Tests include a cluster whose base and mark are available only in different
fonts: it is missing, never spliced across faces. This is a nominal cmap
candidate probe, not completed font fallback. Font-aware canonical decomposition,
variation selectors, post-shaping missing-glyph retries and cascade partitioning
remain required.

`cmake/NativeTextEngine.cmake` defines a production CPU object-library target,
independent of test fixtures and entry points. The application and pipeline
conformance executable share its compiled objects. The library includes the
explicit asset-loading shell; per-item shaping performs no filesystem reads.
This build integration does **not** switch the editor's text drawing path.

Fresh application, GPU-render and affected CPU targets built successfully.
All 76 registered tests passed, including the new pipeline test for source-
mapped Turkish/Arabic glyphs and positions, range errors, joining context and
cluster coverage. The optional read-only real-note check produced 11 items,
4,416 glyphs and 419 output mark hints, with zero visible missing glyphs,
source-span violations, nonzero mark advances or shaping failures. This tests
the CPU output, not pixels, wrapping or caret behaviour. The note's SHA-256
remained `98311d87cf1c846b1502fabd4ee1c90519f7cf0764b2e484659cd8f4ba42bbcb`.

Repeat the optional check with the configured test fonts and a note path:

```sh
./build/native_text_shape_conformance ./build ./vendor/unicode/18.0.0 \
  "$latin_font" "$arabic_font" "$note_path"
```

Isolated Xvfb direct-ID/frozen-run GPU tests and all four application selftests
passed, with `live=1530113` (`start_ms=48`, `rss_kb=107260`). Buf ownership
counts do not establish whole-heap leak freedom. Logs:
`/tmp/anthracite-native-pipeline-final-build.log`,
`/tmp/anthracite-native-pipeline-final-tests.log`,
`/tmp/anthracite-pipeline-xvfb.FpAn13/`.

Production drawing still enters `font_draw_buf`'s legacy wrappers. Shared
pixel layout, production face/cache generation ownership, visual ordering/L4
and actual editor adoption remain pending; the display problem is not yet
claimed fixed in the editor.

## Font-owned shaping/raster bridge checkpoint (2026-10-14)

`Font` now owns separate lazy native shape caches and generation counters for
its primary and fallback files. Successful replacement disposes the selected
cache before freeing its font bytes and advances that face's generation.
Failed file ingestion leaves both generation and cache unchanged. Font
destruction releases the shape caches before their borrowed byte owners.
Atlas fallback swaps do not swap logical shape-cache identities.

`font_shape_native_item` borrows the actual Font-owned face bytes and immutable
cache through its singular representation owner. Cache lifecycle, face
availability, shaping delegation, binding validation and drawing have separate
ATS2 modules/private owner includes; no eighth assume, unsafe cast, font-byte
clone or algorithmic C was introduced. Assets and paragraph owners are still
supplied explicitly by the caller, not loaded during drawing.

The returned `FontNativeRun` owns a frozen positioned run with a role, registry
ID and face-generation token. `font_draw_native_run` validates that token and
the current size before entering the existing direct-ID GPU raster path.
Replacing a face rejects its old runs even if the new face has identical
glyph counts and units. The untouched other face remains drawable. Restoring
the same ppem permits a still-current run to be reused; changing the ppem
rejects it. Registry IDs cannot change within a cached generation.

This is per-Font generation protection, **not** a completed global face
registry: callers must provide nonnegative IDs unique across live faces.
Automatic registry allocation and its cross-owner/ABA lifetime guarantees
remain required. The older raw `font_draw_positioned` API retains its explicit
caller-fixed-face contract and does not acquire this token protection.

Fresh application and renderer builds succeeded. All 76 registered CPU tests
passed. The extended isolated Xvfb renderer suite also passed actual
Font-owned Turkish/Arabic shaping and direct-ID drawing, repeated cache use,
primary/fallback invalidation, fresh replacement runs, failed load preservation,
ppem changes and registry-key rejection. Space glyphs carry advance but produce
no bitmap; drawn-quad assertions distinguish ink from glyph counts. These
checks validate raster/dispatch results, not a pixel-readback reference image.
All four application selftests passed with `live=1530113`
(`start_ms=47`, `rss_kb=107176`). Buf counts do not measure all ATS allocations.
Logs: `/tmp/anthracite-font-owned-build.log`,
`/tmp/anthracite-font-owned-tests.log`,
`/tmp/anthracite-font-owner-final.pUkr1z/`.

To enable this optional renderer suite, append generated-data and Unicode-source
roots to the existing four fixture/font arguments of `font_render_conformance`.
The original four-argument invocation remains supported.

The editor still calls its legacy `font_draw_buf` wrappers. This new Font-owned
API is ready for shared pixel layout/editor adoption; it is not yet selected
as the general UI rendering path.

## Shared single-paragraph layout checkpoint (2026-10-14)

`FontSpanLayout` owns normalized source-mapped analysis, logical items, frozen
Font-owned runs, visual item order and 26.6-pixel extents. `font_span_width`
and `font_span_draw` consume the same positioned result: drawing performs no
second normalization, shaping or advance measurement. The input Buf can be
freed after construction; source byte spans remain those of the original
UTF-8 input, including canonically composed Turkish letters and Arabic marks.

Ownership/allocation, item shaping, installation, ordering, queries, binding
preflight and drawing are separate small ATS2 modules. Run slots use native
linear array proofs and temporary typed cell loans; there are no additional
representation assumptions, unsafe casts or algorithmic C implementations.
Before drawing any item, the snapshot checks every face-generation and ppem
binding. A changed second face rejects the snapshot before the first face is
drawn. This is binding preflight, not transactional GPU rollback for a later
raster/atlas error.

Candidate selection now checks the complete logical item's nominal cmap
coverage (including all non-default-ignorable marks). Arabic prefers the
fallback role but can use a covered primary face; other items prefer primary.
Neither candidate covering the item returns an explicit shaping rejection
instead of silently accepting missing nominal glyphs. This is intentionally
**conservative whole-item selection**, not completed per-EGC font partitioning,
font-aware canonical fallback or post-shaping retry. Two fonts each covering
different clusters of one item can still cause rejection.

This API accepts one unwrapped paragraph. It rejects multi-paragraph input;
it does not choose soft-wrap boundaries, reshape wrapped runs or create a
height/caret/selection map. Its item ordering uses the existing UAX #9 line
permutation; it does not complete font-specific L4 or broader script profiles.
Unicode data remains explicitly caller-owned and is not loaded during drawing.
The legacy editor wrappers are unchanged: this checkpoint is not an assertion
that the user's note now renders correctly in the general editor.

Fresh application, renderer and native CPU shaping targets built successfully.
All 76 registered CPU tests passed. The isolated Xvfb suite passed mixed
Turkish/Arabic measurement/drawing after releasing the source Buf, empty input,
2,560-character input without the legacy 2,048-byte truncation, original source
spans, RTL Arabic, primary-face Arabic when the preferred face lacks coverage,
missing-glyph/multi-paragraph rejection and stale second-face preflight.
Arabic width was 791 in 26.6 at 16 ppem, matching the independent HarfBuzz
oracle for the same Noto Naskh font. These are dispatch/metric tests, not a
pixel-readback comparison.

All four application selftests passed with `live=1530113`, `start_ms=46` and
`rss_kb=106356`. Buf accounting does not measure every ATS/native allocation.
Logs: `/tmp/anthracite-span-final-build.log`,
`/tmp/anthracite-span-source-build.log`,
`/tmp/anthracite-span-final-tests.log`,
`/tmp/anthracite-span-verified.CH4xMO/`.

## Font text session and API dispatch checkpoint (2026-10-14)

`Font` can now own a `FontTextSession`, initialized explicitly through
`font_text_enable`. The session owns Unicode assets, a bounded immutable
span-layout cache and an independently bounded pixel-measurement cache.
Resource initialization, lifecycle, source-key comparison,
snapshot construction, measurement, rendering, scaling, error handling and
ABI adapters are separate small ATS2 modules. Font destruction releases the
cached snapshot and its source key before the Unicode assets and font caches.
No additional `assume`, unsafe conversion or algorithmic C was introduced.

The source key is an owned exact UTF-8 copy made only on a cache miss. Cache
hits compare bytes, length, ppem and every face-generation binding; mutable
scratch buffers cannot create a pointer-identity/content-hash collision.
Successful measurement followed by drawing reuses the positioned layout.
This is a **span cache**, not a completed document/version layout
cache or shared wrapped-line/height/caret snapshot.

With an enabled session, `font_draw`, `font_width`, `font_draw_buf`,
`font_width_buf`, `font_draw_at` and scaled drawing use native shaping and
direct glyph-ID rendering. The C compatibility draw/width wrappers bypass
Presentation Forms processing for that session. Raw C spans are copied at a
bounded memory ABI adapter; Buf calls avoid that extra ingress copy. Explicit
span lengths are bounded by Buf capacity, matching existing scratch-buffer
callers rather than incorrectly relying on their often-unset Buf length.

Scaled drawing shapes and rasterizes at the requested integer ppem instead
of stretching already-shaped legacy glyphs. The base ppem is restored before
returning, and raster cache keys retain ppem. Rational scale factors currently
resolve to integer ppem by truncation, with an explicit 1–96 ppem capacity
limit; arbitrary fractional-size shaping is not claimed. The legacy top-edge
baseline convention is preserved.

Font partitioning now selects a candidate for each whole extended grapheme
cluster, then coalesces adjacent clusters with the same candidate inside
existing script/BiDi item boundaries. Complementary primary/fallback coverage
therefore no longer rejects an otherwise covered whole item. A base and its
marks cannot be split between fonts. Paragraph Arabic context remains shared
across partitions. This supersedes the preceding checkpoint's conservative
whole-item limitation, but **not** font-aware canonical decomposition,
variation-selector coverage or post-shaping fallback retries.

The typed service returns explicit inactive/layout failures. The legacy int
compatibility interface fails deterministically on a native layout error; it
does not silently revert to Presentation Forms or fabricate a width. This
strict compatibility behavior is **not** a completed editor missing-glyph or
unsupported-script presentation policy. Callers still allocate unique live
face IDs under the existing registry contract.

Fresh application, native CPU shaping and renderer builds succeeded; all 76
registered CPU tests passed. The extended isolated Xvfb suite also passed
source mutation with unchanged advance (verifying cache content invalidation),
measurement/drawing reuse, C wrapper and raw API dispatch, scaled rendering
and base-ppem restoration, failed asset load preserving the inactive state,
repeated initialization, complementary-font item splitting and indivisible
base/mark fallback. Buf ownership balanced after full session destruction.

The user's complete note was read unchanged and every line measured/drawn
through the enabled native service with `native_note_render errors=0`. This
checks metric/raster dispatch, **not** pixel-readback accuracy, actual workspace
rendering, wrapping or cursor interaction. Its SHA-256 remains
`98311d87cf1c846b1502fabd4ee1c90519f7cf0764b2e484659cd8f4ba42bbcb`.
The optional note check is enabled by `ANTHRACITE_NATIVE_TEST_NOTE` when running
the extended renderer suite.

All four application selftests passed with `live=1530113`, `start_ms=47`,
`rss_kb=106748`. Buf counts do not measure all ATS/native allocations.
Logs: `/tmp/anthracite-text-partition-build.log`,
`/tmp/anthracite-text-abi-build.log`,
`/tmp/anthracite-text-partition-tests.log`,
`/tmp/anthracite-text-service-final.mBKQ0m/`.

At this checkpoint normal workspace startup did **not yet enable** this session. Its
wrapping, caret/selection and direction helpers still use legacy geometry;
enabling shaping alone would leave those consumers inconsistent. Default
workspace activation requires completing those consumers and a nonfatal,
typed missing-glyph/unsupported-script UI policy, not merely adding an
initialization call. The following checkpoint enables it at the user's explicit
request to follow the running migration in the real editor.

## Default workspace activation checkpoint (2026-10-14)

`workspace_font_start` now prepares the native Font session before the event
loop, including font-load retries. Initialization, configured data paths,
fallback-font loading and UI status are independent small ATS2 modules. CMake
generates ATS2 path constants for each build directory and makes the executable
depend on all required Unicode data-generation targets. No special activation
flag is needed. Selftest remains isolated from normal startup and retains its
original Buf budget.

The Arabic fallback is now the unmodified, bundled static Noto Naskh Arabic
Regular 2.019, SHA-256
`2d5d78e9cc27d7193926c7e460314c9da7dbec1268494dbf117adc53c171ac06`.
CMake checks this hash; copyright, SIL OFL 1.1 and provenance are included under
`vendor/fonts/notonaskh-arabic`. This is font data, not a shaping-library
dependency. Real workspace testing exposed that the system Arabic face
(DejaVu Sans) lacked the note's U+FDFA `ﷺ`; nominal EGC coverage correctly
rejected it. The bundled font resolves that reproducible coverage failure.

Real editor testing also exposed `doc_advance_cps` stopping immediately after
a multibyte lead byte. Wrap-prefix measurement consequently received a partial
UTF-8 sequence and U+FFFD instead of the intended character. Doc navigation and
counting now borrow a four-byte window and share the native strict UTF-8
maximal-subpart kernel with Buf decoding. They allocate no temporary source
buffer and never stop inside a valid scalar. Two-, three- and four-byte scalars,
gap relocation and truncated malformed input have regressions. This fixes
**scalar boundaries**, not complete grapheme-aware navigation/wrap policy.
Both decoder adapters still pass the flat-result/no-payload-allocation check.

Tab stops are typed layout parts, measured from the actual shaped space
advance and logical pen, at four-space intervals. CR/LF line terminators are
zero-advance, non-drawing parts. Their binding runs preserve face/ppem
invalidation; original source spans live in the part metadata, not the
synthetic space run used for that binding. Rendering does not emit space ink
or missing-glyph boxes for these controls. This is not a general multiline
layout API: the workspace still splits physical lines and the span API still
rejects multiple paragraphs.

Native row alignment now queries the same cached layout's Unicode paragraph
base direction rather than the legacy Arabic-presence heuristic. Mixed text
beginning with Turkish remains LTR; Arabic-leading text remains RTL. Styled
multiline slices use the existing physical-line iterator instead of passing
multiple paragraphs to a single-span query. RTL width is measured before the
wrap loop mutates its scratch buffer. The wrap-arrow decoration is an ATS2
vector icon, so changing a content font cannot fail on the UI's U+21B5 marker.
Paragraph-wide soft-wrap BiDi reuse, cluster L3 and font-specific L4 remain
separate unfinished work.

Progress is visible in Settings and structured startup/first-present logs.
Data/font paths can be overridden with `ANTHRACITE_TEXT_DATA`,
`ANTHRACITE_UNICODE_SOURCE` and `ANTHRACITE_ARABIC_FONT`. Missing or invalid
assets cause an explicit initialization failure, not silent legacy fallback.
`ANTHRACITE_CONFIG_DIR` provides a separate configuration directory for
isolated test runs; the normal configuration location is unchanged.

The user's actual note now opens through normal workspace startup with its
Source Code Pro ExtraLight primary font and the bundled Arabic fallback. The
first frame completed in isolated Xvfb, and the process remained alive until
the test timeout. Source SHA-256 was unchanged. Read/edit and full/block embed
fixtures also survived startup. These are real dispatch/frame tests, not
pixel-readback or interactive cursor-accuracy certification.

Fresh application, renderer, UTF-8 conformance and native CPU shaping targets
built. All 76 CPU tests passed; the extended GPU suite passed native startup,
the user's note, source mapping/ownership, tabs/CRLF, paragraph direction,
font partitioning, scaling and Doc scalar navigation. All four application
selftests passed with `live=1530113`, `start_ms=45`, `rss_kb=110140`.
Buf accounting is not whole-heap leak accounting.
Logs: `/tmp/anthracite-workspace-navigation-final-build.log`,
`/tmp/anthracite-workspace-wrap-icon-build.log`,
`/tmp/anthracite-workspace-first-frame-build.log`,
`/tmp/anthracite-workspace-final-ctest.log`,
`/tmp/anthracite-workspace-native.Fpljcb/`.

**Known runtime restriction:** unsupported scripts or clusters uncovered by
both configured faces no longer terminate the editor (see the nonfatal
presentation checkpoint above). Per-glyph post-shaping fallback, font-aware
canonical fallback and a broader face cascade remain required.
Default activation does not mean the whole migration is finished.

## Runtime performance checkpoint (2026-10-14)

The reported idle CPU issue is not considered universally resolved: the isolated
Xvfb/software-GL reproduction already blocked in `poll` at true idle before
these changes. However, every incoming event previously requested a full draw,
and the real Turkish/Arabic note took approximately 1.4–1.5 seconds per redraw.
Debugger sampling identified repeated font coverage and GPOS execution reached
from `plain_px_end`, rather than a GPU-only bottleneck.

The runtime now distinguishes `RepaintClean` and `RepaintNeeded`. Unknown events
and selection requests do not repaint; Expose is explicitly represented and
does repaint. Non-drag pointer motion inside the document updates pointer state
without requesting a frame; chrome hover and drag interactions remain active.
At most 64 queued events are dispatched before presentation, preventing an
unbounded input stream from starving drawing. `plat_wait` checks Xlib's already
buffered event queue before blocking on the connection file descriptor.

The font session now separates two owned resources:

- Immutable positioned spans: up to 128 entries, with 256 KiB of retained
  source keys (an individually larger active span can exceed that key budget).
  Matching includes exact bytes, size and all face-generation bindings. Cache
  misses no longer reconstruct the existing ownership chain during searching.
- Pixel measurements: 8192 four-way sets in a contiguous 32-bit metadata buffer,
  plus a fixed 2 MiB UTF-8 key arena, totalling 3,276,800 payload bytes per enabled
  font session. Hashes select candidates only; exact bytes, length, ppem and
  both font identities/generations decide a hit. Arena rollover clears all
  metadata before reusing source storage. Collisions and eviction never supply
  an approximate width. Only successful native measurements are inserted.

Trace switches are off by default: `ANTHRACITE_TRACE_FRAMES=1` reports complete
frame-present durations; `ANTHRACITE_TRACE_METRIC_MISSES=1` reports measurement
miss lengths and buckets, not document contents.

Final isolated validation on the unchanged real note, with software GL:

- Cold first frame: 768 ms; this remains a performance limitation.
- Ten warmed Expose frames: 22.7–27.0 ms, compared with about 1.4 seconds earlier.
- Warmed frames: zero measurement-cache misses; the earlier direct-mapped
  prototype had 337 misses and about 210–225 ms per warmed frame.
- Five seconds idle: zero additional process CPU ticks (`CLK_TCK=100`).
- 500 pointer-motion events inside the document: no additional frames and one
  CPU tick, over roughly two seconds including the observation interval.
- All 76 CTest cases, extended GPU/native real-note tests, collision/scale/font
  generation/arena-budget tests and all four application selftests passed.
  Application selftest reports `live=1530113` after cleanup.

Evidence: `/tmp/anthracite-associative-verified.Ke7NY1/`,
`/tmp/anthracite-associative-final-ctest.log`,
`/tmp/anthracite-metric-associative-build.log`.
These are redraw/idle measurements, not an end-to-end typing-latency benchmark.
Cold layout still measures and shapes growing prefixes. Shared document-version
wrapping/height/caret snapshots are still needed to remove that work structurally;
the measurement cache does not substitute for that remaining migration.

## Shared body-row geometry checkpoint (2026-10-14)

The common overlap/selection defect was caused by incompatible geometry:
painting wrapped by measured pixel width, while paragraph heights and selection
rows still divided scalar counts by a character-column estimate. Native text
also continued to use Presentation-Forms-based C clusters for selection and
pointer offsets. The following production path now replaces those computations
for ordinary text when the native session is enabled.

`data_ast/visual_rows` owns flat projected text, an original-byte-to-visible-byte
map, visual row boundaries/widths and per-source-line row indexes. `Doc` owns its
optional snapshot without a new `assume`. Projection, Unicode break admission,
pixel fitting, painting, selection, pointer queries, vertical navigation and
font line metrics are separate small ATS2 modules. The snapshot key includes
document version, exact available width, ppem, row height/baseline, both face identities/generations
and source-versus-rendered projection. Source edit mode retains Markdown;
rendered mode excludes the same hidden markers and link destinations as the
reader, preserving original source offsets rather than modifying the document.

Wrapping admits UAX #14 opportunities only on UAX #29 extended-grapheme
boundaries. An overlong unbreakable token can break at a whole EGC, never at a
UTF-8 continuation or inside a combining sequence. An individually oversized
EGC remains intact and is clipped by the viewport; it is not falsely reported
as fitting. Row widths use the native font service, not an average cell width.
Mandatory breaks remain distinct from optional opportunities (boundary flags
1/3/5). CR/LF, VT, FF, NEL, LS and PS are zero-ink line-end boxes; a mandatory
boundary terminates the visual row even when the available width is not full.

Document height uses these saved row counts. Node heights cover the resulting
source-line extents, and a monotone prefix-maximum node-bottom index feeds
visible-node lookup. Styled ordinary text paints source ranges from the whole
row's frozen positioned glyphs instead of reshaping each colored substring.
Selection backgrounds use actual glyph advances and visual origins, including
font partitions and tab boxes; mixed-direction selections can produce disjoint
rectangles rather than one oversized bounding rectangle. Highlight/underline/
strike/error decorations also consume this row geometry.

Pointer queries and caret drawing use those positioned glyph edges. Pointer
source offsets snap to an EGC boundary. Up/Down and Shift+Up/Down refresh the
snapshot when needed and move through visual pixel rows, preserving the anchor
for extended selection. Other keyboard navigation/deletion commands are not
claimed to have completed the grapheme/visual-affinity migration.
Painting and pointer queries temporarily borrow the snapshot's ppem and restore
the caller's font size afterwards. Changing toolbar/sidebar label font size
does not change an already laid-out document's row height or selection geometry.

The document line box uses primary/fallback ascent and descent metrics, including
the Arabic font, without enlarging fixed-height toolbar/sidebar label metrics.
Embed measurement and child drawing now both prepare pixel row snapshots with
the width actually remaining after the child's gutter/padding. Whole-file and
`#^block` scope remain separate and unchanged.

The GPU regression includes Turkish/Arabic wrapping, paragraph height,
selection-color pixels bounded by the row viewport, widening/reflow, hidden
Markdown/link projection and vertical selection movement. Font-owned cached
source buffers can remain after a document is closed; the enclosing font-service
test checks that they are released with the Font. The fixed application selftest
allocation invariant remains `live=1530113`.

Final validation: all 76 CTest cases passed; the extended native/GPU suite reports
`native_visual_layout errors=0` and `native_text_service ... balanced=true`.
The regression also changes the shared Font from 16 to 48 ppem after laying out
a document: caret coordinates and selection bounds remain unchanged and the
caller's font size is restored. Unicode paragraph/vertical-tab hard-break and
CRLF cases, hidden Markdown/link projection and vertical navigation pass.
All four selftests pass with `live=1530113` (latest `start_ms=46`, `rss_kb=110204`).

On the currently available real note in isolated Xvfb/software GL: the first
frame took about 799 ms; six unchanged Expose frames took 1.8–3.0 ms; five
seconds idle added zero process CPU ticks. A first narrow resize/reflow took
about 348 ms and the return to wide layout about 52 ms. Cold/reflow work therefore
remains significant even though unchanged frames no longer repeat prefix fitting.
The note content changed during development outside this implementation; these
latest timings are not a controlled comparison against the earlier note version.
The final diagnostic run preserved the observed source-file hash
`98e3bed3326390ba3d18f651483cfaedf3a5ab416ca2aa9b2f87fac309b93c15`.
Evidence: `/tmp/anthracite-shared-handoff.1ES0Xc/`,
`/tmp/anthracite-row-invariants.Ou1AgI/`,
`/tmp/anthracite-row-invariants-ctest.log`,
`/tmp/anthracite-shared-geometry-hard-lines-build.log`.

Remaining limitations: each wrapped row still reanalyzes BiDi rather than owning
one paragraph analysis with line-level L1/L2 processing; full L3/L4 integration
is not finished. GDEF ligature caret points and partial-ligature selection are
not implemented. Native ink can have overhang beyond an advance box; this step
does not implement a universal ink-bounds line-height policy. Scaled headings,
math/replaced blocks and some specialized block geometry still use their
dedicated paths. Child document lifetime/caching and paragraph incremental
layout are still required. Cold fitting still measures growing prefixes, but
completed row snapshots avoid repeating that work on an unchanged frame.

## Nonfatal presentation checkpoint (2026-10-14)

The strict compatibility failure no longer terminates the editor for
missing-glyph or unsupported-script items. `FontSpanFailure` gained typed
`SpanMissing` and `SpanUnsupported` variants, and `FontSpanPartKind` gained
`SpanSkipPart`. A cluster uncovered by both faces now shapes with the primary
face's real `.notdef` glyph zero through the existing full GSUB/GPOS pipeline
(zero-ink, nonzero advance), so selection/caret geometry stays exact. An item
whose OpenType script request is unsupported installs a zero-ink, zero-advance
skip part that keeps its source range; paint, draw and hit testing all skip it.
Both outcomes keep the span accepted; row painting, selection, pointer queries
and vertical navigation continue with the remaining items. Analysis, item,
context and capacity failures remain fatal typed rejections, and the legacy
`font_text_result_pixels` die path still covers them.

`font_span_check` preflight now treats skip slots as intentionally absent
instead of reporting `FontRunGraph`. The shaping-failure log gained an error
detail field. The previously broken `source_edit_cases` list-literal type
mismatch (present on HEAD) was fixed by using the non-linear `List0` type.

The new `native_span_missing_cases` conformance covers emoji `.notdef`
rasterization with preserved source spans, a Hebrew word rejected by both faces
producing zero width and no failure, mixed Turkish/unsupported-script text
preserving surrounding ink, paragraph direction and preflight readiness after
skip parts, and the workspace service path drawing mixed content without
aborting. All 77 registered CTest cases pass. The isolated Xvfb suite reports
zero errors across glyph-ID, run render, span, cache, repaint, metrics,
visual-layout, source-edit, service, partition, workspace-startup, navigation
and owner checks; all four application selftests pass with `live=1530113`
(`start_ms=43`, `rss_kb=110064`). The real note check reports `items=10
glyphs=4413 missing=0 failures=0`.

Remaining: per-glyph post-shaping fallback, font-aware canonical decomposition,
automatic face registry and the generic symbol-face policy are still open; skip
parts intentionally drop ink instead of drawing another font's glyphs.

## Profile/caret/registry checkpoint (2026-10-15)

Hebrew joins Latin/Greek/Cyrillic in the common horizontal shaping profile, so
covered Hebrew text now shapes with real glyphs instead of falling into the
skip presentation. `GdefHeader`'s previously validated-but-unused `attach` and
`carets` children now have checked readers: AttachList stores per-glyph
AttachPoint descriptors behind a typed Coverage-to-index map (checked u16
offsets, point counts and glyph domains; the empty table is an explicit
accepted-nothing result), and LigCaretList parses LigGlyph caret value offsets
into CaretValue descriptors supporting formats 1 (signed coordinate), 2
(contour index) and 3 (coordinate plus a borrowed Device span). Out-of-domain
glyphs and indices return typed empty results instead of guesses. The new
`gdef_attach_cases` conformance exercises valid tables, absent children, every
representative truncation, invalid formats/orders, glyph coverage misses and
balanced Buf ownership. All GDEF conformance suites pass.

`Font` now carries an automatic registry ID. `font_registry_next` allocates
strictly increasing positive integers that never repeat (ABA-safe against
disposed faces) from a C-side airlock, with a deterministic abort at int
exhaustion; `font_registry_id` exposes it. Conformance checks uniqueness
across concurrent faces and strict monotonicity after a face is freed.

All 77 CTest cases pass, including gdef_conformance with zero attach/caret
errors. The isolated Xvfb suite reports zero errors; the real note check
reports `items=10 glyphs=4413 missing=0 failures=0`; the four selftests stay at
`live=1530113` with `start_ms=43` and `rss_kb=110064`.

## Still required

Normal workspace startup now uses native shaping and direct-ID drawing, with
native cached row direction for alignment and shared ordinary body-row geometry.
Specialized geometry and full paragraph/ligature interaction have not all migrated. Therefore
the reported mixed Turkish/Arabic display and interaction problem is **not yet
resolved in full**, despite successful real-note startup/frame tests.

Remaining plan work includes specialized-block pixel wrapping, normalization/BiDi/line rendering
integration (including L3 glyph-cluster ordering and font-specific L4 handling),
Font-aware canonical and post-shaping fallback, legacy-kern/mark fallback
positioning, FeatureParams/FeatureVariations/ItemVariationStore evaluation and
the generic symbol-face policy (missing-glyph and unsupported-script items now
degrade nonfatally through skip parts and .notdef glyphs; the registry now
auto-allocates unique IDs; `font_text_enable` now allocates its primary and
fallback face IDs from that registry on success, so two live fonts never share
native-cache identities). Rendering, wrapping,
height, caret/selection and specialized child blocks must finish adopting shared layout
snapshots. The Arabic fallback is bundled; a reproducible primary/generic
symbol-face policy is still required.
The common OpenType readers, layout topology/planning and GDEF class/mark-filter
capabilities now feed cached GSUB/GPOS execution in production rendering.
Broader script profiles beyond horizontal common/Arabic, GDEF attachment
points and ligature carets, FeatureParams interpretation,
FeatureVariations and ItemVariationStore evaluation remain unimplemented.
GSUB 1–8 and GPOS 1–9 have font-scoped cached execution and transactional
script schedules. Joiner/default-ignorable matching policies, legacy-kern/mark
fallback positioning, broader font/run fallback and production source-mapped
layout integration remain required.

The BiDi paragraph and line algorithms pass the official tests through L2,
and now feed production single-span drawing and row direction. Codepoint mirror mappings
do not replace font-specific mirrored glyphs for characters without a Unicode
mirror partner.

The current rasterizer still has its old limits (including outline depth and
bitmap/atlas limits). Component grid fitting, phantom-point attachments,
`USE_MY_METRICS` processing, TrueType instruction execution, variable fonts and
CFF are not newly implemented by this stage. Component flags are parsed
explicitly; parsing them does not imply these capabilities are implemented.
