staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/normalization/normalization_types.sats"
datavtype NormalizationColumns = NormalizationColumns of (ScalarText, ScalarText, ScalarText, ScalarText, ScalarText)
datatype NormalizationTestPart = SpecificPart | CharacterPart | CanonicalPart | CompatibilityPart | ClosurePart | CompositePart
typedef NormalizationTestScores = @{cases=int, errors=int}
typedef NormalizationTestState = @{part=NormalizationTestPart, scores=NormalizationTestScores}
fun normalization_fixture_columns(source: !Buf, start: int, finish: int): NormalizationColumns
fun normalization_fixture_dispose(columns: NormalizationColumns): void
fun normalization_fixture_test(data: !NormalizationData, columns: !NormalizationColumns): int
fun normalization_fixture_mark(columns: !NormalizationColumns, mask: !Buf, part: NormalizationTestPart): void
fun normalization_fixture_stable(data: !NormalizationData, mask: !Buf): int
