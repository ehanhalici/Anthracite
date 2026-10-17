staload "mem.sats"

(* Static TrueType faces. Parsing owns no GPU resources and never rewrites
   source bytes. Table spans and cmap structures are checked at ingestion. *)
typedef SfntSpan = @{offset=int, length=int}

datatype SfntTable =
  | TableHead | TableHhea | TableMaxp | TableCmap | TableLoca | TableGlyf
  | TableHmtx | TableKern | TableGsub | TableGpos | TableGdef | TableFvar

datavtype SfntOptional = NoSfntTable | HasSfntTable of SfntSpan
datatype SfntCmapKind = CmapSegmented | CmapGrouped
typedef SfntCmap = @{kind=SfntCmapKind,span=SfntSpan,count=int}

datatype SfntErrorKind = SfntReadError | SfntDirectoryError | SfntContainerError
  | SfntOutlineError | SfntVariableError | SfntMetricsError | SfntCharacterMapError | SfntLocationsError
typedef SfntError = @{kind=SfntErrorKind,code=int}
macdef SfntIo(code) = @{kind=SfntReadError(),code=,(code)}
macdef SfntDirectory() = @{kind=SfntDirectoryError(),code=0}
macdef SfntContainer() = @{kind=SfntContainerError(),code=0}
macdef SfntOutline() = @{kind=SfntOutlineError(),code=0}
macdef SfntVariable() = @{kind=SfntVariableError(),code=0}
macdef SfntMetrics() = @{kind=SfntMetricsError(),code=0}
macdef SfntCharacterMap() = @{kind=SfntCharacterMapError(),code=0}
macdef SfntLocations() = @{kind=SfntLocationsError(),code=0}

typedef SfntInfo = @{
  tables=int, units=int, ascender=int, descender=int, line_gap=int,
  glyphs=int, hmetrics=int, long_loca=bool,
  glyf=SfntSpan, loca=SfntSpan, hmtx=SfntSpan, cmap=SfntCmap
}

datavtype SfntParsed = ValidSfnt of SfntInfo | InvalidSfnt of SfntError
typedef SfntMetadata = @{present=bool,info=SfntInfo}
fun sfnt_metadata_empty(): SfntMetadata
datavtype SfntFace = SfntFace of (Buf, SfntInfo)
datavtype SfntLoaded = LoadedSfnt of SfntFace | RejectedSfnt of SfntError

typedef GlyphMetrics = @{advance=int, bearing=int}

(* Byte readers require an already checked containing span. The unsigned
   32-bit reader rejects values beyond the supported signed offset domain. *)
fun sfnt_be16(b: !Buf, offset: int): int
fun sfnt_signed16(b: !Buf, offset: int): int
fun sfnt_be32(b: !Buf, offset: int): int
fun sfnt_contains(span: SfntSpan, offset: int, size: int): bool
fun sfnt_table_code(table: SfntTable): int
fun sfnt_table(b: !Buf, count: int, table: SfntTable): SfntOptional
fun sfnt_parse(b: !Buf): SfntParsed
fun sfnt_open(path: string): SfntLoaded
fun sfnt_dispose(face: SfntFace): void
fun sfnt_info(face: !SfntFace): SfntInfo
fun sfnt_map(b: !Buf, info: SfntInfo, cp: int): int
fun sfnt_metrics(b: !Buf, info: SfntInfo, gid: int): GlyphMetrics
fun sfnt_glyph(face: !SfntFace, cp: int): int
fun sfnt_glyph_metrics(face: !SfntFace, gid: int): GlyphMetrics
