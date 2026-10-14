#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/text_source.sats"
staload "data_font/sfnt.sats"

implement sfnt_be16(b,p) = iadd(imul(buf_get(b,p),256),buf_get(b,iadd(p,1)))
implement sfnt_signed16(b,p) = let val v = sfnt_be16(b,p) in
  if ige(v,32768) then isub(v,65536) else v end
implement sfnt_be32(b,p) = let val hi = sfnt_be16(b,p) in
  if igt(hi,32767) then ~1 else iadd(imul(hi,65536),sfnt_be16(b,iadd(p,2))) end

implement sfnt_contains(span,p,n) =
  ige(p,0) andalso ige(n,0) andalso ile(p,span.length)
  andalso ile(n,isub(span.length,p))

implement sfnt_table_code(t) = case+ t of
  | TableHead() => 1751474532 | TableHhea() => 1751672161
  | TableMaxp() => 1835104368 | TableCmap() => 1668112752
  | TableLoca() => 1819239265 | TableGlyf() => 1735162214
  | TableHmtx() => 1752003704 | TableKern() => 1801810542
  | TableGsub() => 1196643650 | TableGpos() => 1196445523
  | TableGdef() => 1195656518 | TableFvar() => 1719034226

fun table_span(b: !Buf, p: int): SfntSpan =
  @{offset=sfnt_be32(b,iadd(p,8)),length=sfnt_be32(b,iadd(p,12))}

fun directory_search {n:nat} .<n>. (
  n: int(n), b: !Buf, p: int, tag: int
): SfntOptional =
  if n = 0 then NoSfntTable() else let val current = sfnt_be32(b,p) in
    if ieq(current,tag) then HasSfntTable(table_span(b,p))
    else if igt(current,tag) then NoSfntTable()
    else directory_search(n-1,b,iadd(p,16),tag)
  end

implement sfnt_table(b,count,table) =
  directory_search(airlock_nat(count),b,12,sfnt_table_code(table))

fun span_valid(span: SfntSpan, length: int, floor: int): bool =
  ige(span.offset,floor) andalso ieq(imod(span.offset,4),0)
  andalso ile(span.offset,length) andalso ige(span.length,0)
  andalso ile(span.length,isub(length,span.offset))

fun directory_valid {n:nat} .<n>. (
  n: int(n), b: !Buf, p: int, previous: int, floor: int
): bool =
  if n = 0 then true else let val tag = sfnt_be32(b,p) in
    if ile(tag,previous) orelse not(span_valid(table_span(b,p),buf_len(b),floor)) then false
    else directory_valid(n-1,b,iadd(p,16),tag,floor)
  end

fun index_fill {n:nat} .<n>. (n: int(n), indices: !Buf, i: int): void =
  if n = 0 then () else let val () = buf_set32(indices,i,i) in index_fill(n-1,indices,iadd(i,1)) end

fun offset_digit(b: !Buf, index: int, divisor: int): int =
  imod(idiv(sfnt_be32(b,iadd(20,imul(index,16))),divisor),256)

fun radix_count {n:nat} .<n>. (
  n: int(n), b: !Buf, indices: !Buf, counts: !Buf, i: int, divisor: int
): void =
  if n = 0 then () else let
    val digit = offset_digit(b,buf_get32(indices,i),divisor)
    val () = buf_set32(counts,digit,iadd(buf_get32(counts,digit),1))
  in radix_count(n-1,b,indices,counts,iadd(i,1),divisor) end

fun radix_prefix {n:nat} .<n>. (n: int(n), counts: !Buf, i: int, total: int): void =
  if n = 0 then () else let
    val count = buf_get32(counts,i)
    val () = buf_set32(counts,i,total)
  in radix_prefix(n-1,counts,iadd(i,1),iadd(total,count)) end

fun radix_scatter {n:nat} .<n>. (
  n: int(n), b: !Buf, input: !Buf, output: !Buf, counts: !Buf, i: int, divisor: int
): void =
  if n = 0 then () else let
    val index = buf_get32(input,i)
    val digit = offset_digit(b,index,divisor)
    val at = buf_get32(counts,digit)
    val () = buf_set32(output,at,index)
    val () = buf_set32(counts,digit,iadd(at,1))
  in radix_scatter(n-1,b,input,output,counts,iadd(i,1),divisor) end

fun radix_passes {n:nat} .<n>. (
  n: int(n), b: !Buf, input: !Buf, output: !Buf, counts: !Buf, count: int, divisor: int
): void =
  if n = 0 then () else let
    val () = buf_zero(counts)
    val () = radix_count(airlock_nat(count),b,input,counts,0,divisor)
    val () = radix_prefix(256,counts,0,0)
    val () = radix_scatter(airlock_nat(count),b,input,output,counts,0,divisor)
    val next = if n = 1 then divisor else imul(divisor,256)
  in radix_passes(n-1,b,output,input,counts,count,next) end

fun disjoint_ranges {n:nat} .<n>. (
  n: int(n), b: !Buf, sorted: !Buf, i: int, previous_end: int
): bool =
  if n = 0 then true else let
    val span = table_span(b,iadd(12,imul(buf_get32(sorted,i),16)))
  in if ieq(span.length,0) then disjoint_ranges(n-1,b,sorted,iadd(i,1),previous_end)
    else if ilt(span.offset,previous_end) then false
    else disjoint_ranges(n-1,b,sorted,iadd(i,1),iadd(span.offset,span.length)) end

fun tables_disjoint(b: !Buf, count: int): bool = let
  val indices = buf_make(imul(count,4))
  val scratch = buf_make(imul(count,4))
  val counts = buf_make(1024)
  val () = index_fill(airlock_nat(count),indices,0)
  val () = radix_passes(4,b,indices,scratch,counts,count,1)
  val result = disjoint_ranges(airlock_nat(count),b,indices,0,0)
  val () = buf_free(indices)
  val () = buf_free(scratch)
  val () = buf_free(counts)
in result end

fun directory_header(b: !Buf): bool = let
  val n = sfnt_be16(b,4)
  val floor = iadd(12,imul(n,16))
in ige(buf_len(b),floor) andalso igt(n,0)
  andalso directory_valid(airlock_nat(n),b,12,0,floor)
  andalso tables_disjoint(b,n) end

fun present_size(table: SfntOptional, size: int): bool = case+ table of
  | NoSfntTable() => false | HasSfntTable(span) => ige(span.length,size)

fun table_offset(table: SfntOptional): int = case+ table of
  | NoSfntTable() => ~1 | HasSfntTable(span) => span.offset

fun required_tables(b: !Buf, n: int): bool =
  present_size(sfnt_table(b,n,TableHead()),54)
  andalso present_size(sfnt_table(b,n,TableHhea()),36)
  andalso present_size(sfnt_table(b,n,TableMaxp()),32)
  andalso present_size(sfnt_table(b,n,TableCmap()),4)
  andalso present_size(sfnt_table(b,n,TableLoca()),2)
  andalso present_size(sfnt_table(b,n,TableGlyf()),0)
  andalso present_size(sfnt_table(b,n,TableHmtx()),4)

fun metrics_valid(b: !Buf, n: int): bool = let
  val h = table_offset(sfnt_table(b,n,TableHead()))
  val a = table_offset(sfnt_table(b,n,TableHhea()))
  val m = table_offset(sfnt_table(b,n,TableMaxp()))
  val units = sfnt_be16(b,iadd(h,18))
  val fmt = sfnt_signed16(b,iadd(h,50))
  val glyphs = sfnt_be16(b,iadd(m,4))
  val hm = sfnt_be16(b,iadd(a,34))
  val bytes = iadd(imul(hm,4),imul(isub(glyphs,hm),2))
in ieq(sfnt_be32(b,iadd(h,12)),1594834165)
  andalso ige(units,16) andalso ile(units,16384)
  andalso (ieq(fmt,0) orelse ieq(fmt,1))
  andalso ieq(sfnt_signed16(b,iadd(a,32)),0)
  andalso ieq(sfnt_be32(b,m),65536) andalso igt(hm,0) andalso ile(hm,glyphs)
  andalso present_size(sfnt_table(b,n,TableHmtx()),bytes) end

fun optional_span(table: SfntOptional): SfntSpan = case+ table of
  | HasSfntTable(span) => span | NoSfntTable() => @{offset=0,length=0}

fun loca_value(b: !Buf, span: SfntSpan, long: bool, i: int): int =
  if long then sfnt_be32(b,iadd(span.offset,imul(i,4)))
  else imul(sfnt_be16(b,iadd(span.offset,imul(i,2))),2)

fun loca_check {n:nat} .<n>. (
  n: int(n), b: !Buf, span: SfntSpan, long: bool, i: int, previous: int, limit: int
): bool =
  if n = 0 then true else let val at = loca_value(b,span,long,i) in
    if ilt(at,previous) orelse igt(at,limit) then false
    else loca_check(n-1,b,span,long,iadd(i,1),at,limit)
  end

fun locations_valid(b: !Buf, n: int): bool = let
  val head = table_offset(sfnt_table(b,n,TableHead()))
  val maxp = table_offset(sfnt_table(b,n,TableMaxp()))
  val count = iadd(sfnt_be16(b,iadd(maxp,4)),1)
  val long = ieq(sfnt_signed16(b,iadd(head,50)),1)
  val loca = optional_span(sfnt_table(b,n,TableLoca()))
  val glyf = optional_span(sfnt_table(b,n,TableGlyf()))
in ige(loca.length,imul(count,if long then 4 else 2))
  andalso loca_check(airlock_nat(count),b,loca,long,0,0,glyf.length) end

typedef cmap_candidate = @{span=SfntSpan,format=int,score=int}

fun cmap_encoding_score(platform: int, encoding: int, format: int): int =
  if ieq(format,12) then (
    if ieq(platform,3) andalso ieq(encoding,10) then 4
    else if ieq(platform,0) andalso ieq(encoding,4) then 3 else 0)
  else if ieq(format,4) then (
    if ieq(platform,3) andalso ieq(encoding,1) then 2
    else if ieq(platform,0) andalso ile(encoding,3) then 1 else 0)
  else 0

fun cmap_candidate_at(b: !Buf, cmap: SfntSpan, p: int): cmap_candidate = let
  val off = sfnt_be32(b,iadd(p,4))
  val exists = sfnt_contains(cmap,off,4)
  val at = if exists then iadd(cmap.offset,off) else cmap.offset
  val fmt = if exists then sfnt_be16(b,at) else 0
  val wide = ieq(fmt,12) andalso sfnt_contains(cmap,off,16)
  val len = if wide then sfnt_be32(b,iadd(at,4)) else sfnt_be16(b,iadd(at,2))
  val ok = exists andalso sfnt_contains(cmap,off,len)
  val score = if ok then cmap_encoding_score(sfnt_be16(b,p),sfnt_be16(b,iadd(p,2)),fmt) else ~1
in @{span= @{offset=at,length=len},format=fmt,score=score} end

fun cmap_choose {n:nat} .<n>. (
  n: int(n), b: !Buf, cmap: SfntSpan, p: int, best: cmap_candidate
): cmap_candidate =
  if n = 0 then best else let val candidate = cmap_candidate_at(b,cmap,p) in
    if ilt(candidate.score,0) then candidate
    else cmap_choose(n-1,b,cmap,iadd(p,8),
      if igt(candidate.score,best.score) then candidate else best)
  end

fun cmap_selection(b: !Buf, cmap: SfntSpan): cmap_candidate = let
  val n = sfnt_be16(b,iadd(cmap.offset,2))
  val none = @{span=cmap,format=0,score=0}
in if not(ieq(sfnt_be16(b,cmap.offset),0)) orelse not(sfnt_contains(cmap,4,imul(n,8)))
  then none else cmap_choose(airlock_nat(n),b,cmap,iadd(cmap.offset,4),none) end

fun cmap4_gid(b: !Buf, span: SfntSpan, segs: int, i: int, cp: int): int = let
  val start = sfnt_be16(b,iadd(span.offset,iadd(16,imul(iadd(segs,i),2))))
  val delta = sfnt_be16(b,iadd(span.offset,iadd(16,imul(iadd(imul(segs,2),i),2))))
  val at = iadd(span.offset,iadd(16,imul(iadd(imul(segs,3),i),2)))
  val range = sfnt_be16(b,at)
  val word = if ieq(range,0) then cp else sfnt_be16(b,iadd(at,iadd(range,imul(isub(cp,start),2))))
in if ine(range,0) andalso ieq(word,0) then 0 else imod(iadd(word,delta),65536) end

fun cmap4_codes {n:nat} .<n>. (
  n: int(n), b: !Buf, span: SfntSpan, segs: int, i: int, cp: int, glyphs: int
): bool =
  if n = 0 then true else if ige(cmap4_gid(b,span,segs,i,cp),glyphs) then false
  else cmap4_codes(n-1,b,span,segs,i,iadd(cp,1),glyphs)

fun cmap4_segment_valid(b: !Buf, span: SfntSpan, segs: int, i: int, previous: int, glyphs: int): bool = let
  val finish = sfnt_be16(b,iadd(span.offset,iadd(14,imul(i,2))))
  val start = sfnt_be16(b,iadd(span.offset,iadd(16,imul(iadd(segs,i),2))))
  val at = iadd(16,imul(iadd(imul(segs,3),i),2))
  val range = sfnt_be16(b,iadd(span.offset,at))
  val bytes = imul(iadd(isub(finish,start),1),2)
in igt(start,previous) andalso ige(finish,start)
  andalso (ieq(range,0) orelse (ieq(imod(range,2),0)
    andalso ige(iadd(at,range),iadd(16,imul(segs,8)))
    andalso sfnt_contains(span,iadd(at,range),bytes)))
  andalso cmap4_codes(airlock_nat(imax(0,idiv(bytes,2))),b,span,segs,i,start,glyphs) end

fun cmap4_segments {n:nat} .<n>. (
  n: int(n), b: !Buf, span: SfntSpan, segs: int, i: int, previous: int, glyphs: int
): bool =
  if n = 0 then ieq(previous,65535)
  else if not(cmap4_segment_valid(b,span,segs,i,previous,glyphs)) then false
  else cmap4_segments(n-1,b,span,segs,iadd(i,1),
    sfnt_be16(b,iadd(span.offset,iadd(14,imul(i,2)))),glyphs)

fun cmap4_valid(b: !Buf, span: SfntSpan, glyphs: int): bool = let
  val doubled = sfnt_be16(b,iadd(span.offset,6))
  val segs = idiv(doubled,2)
in ige(span.length,16) andalso igt(segs,0) andalso ieq(imod(doubled,2),0)
  andalso sfnt_contains(span,16,imul(segs,8))
  andalso ieq(sfnt_be16(b,iadd(span.offset,iadd(14,doubled))),0)
  andalso cmap4_segments(airlock_nat(segs),b,span,segs,0,~1,glyphs) end

fun cmap12_groups {n:nat} .<n>. (
  n: int(n), b: !Buf, p: int, previous: int, glyphs: int
): bool =
  if n = 0 then true else let
    val start = sfnt_be32(b,p)
    val finish = sfnt_be32(b,iadd(p,4))
    val gid = sfnt_be32(b,iadd(p,8))
  in if ile(start,previous) orelse ilt(finish,start) orelse igt(finish,1114111)
    orelse ilt(gid,0) orelse ige(gid,glyphs) orelse ige(isub(finish,start),isub(glyphs,gid)) then false
    else cmap12_groups(n-1,b,iadd(p,12),finish,glyphs) end

fun cmap12_valid(b: !Buf, span: SfntSpan, glyphs: int): bool = let
  val n = sfnt_be32(b,iadd(span.offset,12))
in ige(span.length,16) andalso ieq(sfnt_be16(b,iadd(span.offset,2)),0)
  andalso ige(n,0) andalso ile(n,idiv(isub(span.length,16),12))
  andalso cmap12_groups(airlock_nat(imax(0,n)),b,iadd(span.offset,16),~1,glyphs) end

fun character_map(b: !Buf, n: int, glyphs: int): Option(SfntCmap) = let
  val selected = cmap_selection(b,optional_span(sfnt_table(b,n,TableCmap())))
  val span = selected.span
in if ile(selected.score,0) then None()
  else if ieq(selected.format,4) andalso cmap4_valid(b,span,glyphs)
    then Some(Cmap4(span,idiv(sfnt_be16(b,iadd(span.offset,6)),2)))
  else if ieq(selected.format,12) andalso cmap12_valid(b,span,glyphs)
    then Some(Cmap12(span,sfnt_be32(b,iadd(span.offset,12))))
  else None() end

fun build_info(b: !Buf, n: int, cmap: SfntCmap): SfntInfo = let
  val h = table_offset(sfnt_table(b,n,TableHead()))
  val a = table_offset(sfnt_table(b,n,TableHhea()))
  val m = table_offset(sfnt_table(b,n,TableMaxp()))
in @{tables=n,units=sfnt_be16(b,iadd(h,18)),
  ascender=sfnt_signed16(b,iadd(a,4)),descender=sfnt_signed16(b,iadd(a,6)),line_gap=sfnt_signed16(b,iadd(a,8)),
  glyphs=sfnt_be16(b,iadd(m,4)),hmetrics=sfnt_be16(b,iadd(a,34)),long_loca=ieq(sfnt_signed16(b,iadd(h,50)),1),
  glyf=optional_span(sfnt_table(b,n,TableGlyf())),loca=optional_span(sfnt_table(b,n,TableLoca())),
  hmtx=optional_span(sfnt_table(b,n,TableHmtx())),cmap=cmap} end

fun parse_static(b: !Buf, n: int): SfntParsed =
  if not(required_tables(b,n)) then InvalidSfnt(SfntOutline())
  else if not(metrics_valid(b,n)) then InvalidSfnt(SfntMetrics())
  else if not(locations_valid(b,n)) then InvalidSfnt(SfntLocations())
  else let val m = table_offset(sfnt_table(b,n,TableMaxp())) in
    case+ character_map(b,n,sfnt_be16(b,iadd(m,4))) of
    | None() => InvalidSfnt(SfntCharacterMap())
    | Some(cmap) => ValidSfnt(build_info(b,n,cmap)) end

implement sfnt_parse(b) =
  if ilt(buf_len(b),12) then InvalidSfnt(SfntDirectory())
  else if not(ieq(sfnt_be32(b,0),65536) orelse ieq(sfnt_be32(b,0),1953658213))
    then InvalidSfnt(SfntContainer())
  else if not(directory_header(b)) then InvalidSfnt(SfntDirectory())
  else let val n = sfnt_be16(b,4) in case+ sfnt_table(b,n,TableFvar()) of
    | HasSfntTable(span) => InvalidSfnt(SfntVariable())
    | NoSfntTable() => parse_static(b,n) end

implement sfnt_open(path) = case+ text_file_read(path) of
  | ~TextFileError(code) => RejectedSfnt(SfntIo(code))
  | ~TextFile(b) => (case+ sfnt_parse(b) of
    | ValidSfnt(info) => LoadedSfnt(SfntFace(b,info))
    | InvalidSfnt(error) => let val () = buf_free(b) in RejectedSfnt(error) end)

implement sfnt_dispose(face) = let val+ ~SfntFace(b,info) = face in buf_free(b) end
implement sfnt_info(face) = let val+ SfntFace(b,info) = face in info end

extern fun search_exhausted(): int = "mac#anth_die_int"

fun cmap4_search {n:nat} .<n>. (
  n: int(n), b: !Buf, span: SfntSpan, segs: int, cp: int, lo: int, hi: int
): int =
  if ige(lo,hi) then 0 else if n = 0 then search_exhausted() else let
    val mid = iadd(lo,idiv(isub(hi,lo),2))
    val endcp = sfnt_be16(b,iadd(span.offset,iadd(14,imul(mid,2))))
    val startcp = sfnt_be16(b,iadd(span.offset,iadd(16,imul(iadd(segs,mid),2))))
  in if igt(cp,endcp) then cmap4_search(n-1,b,span,segs,cp,iadd(mid,1),hi)
    else if ilt(cp,startcp) then cmap4_search(n-1,b,span,segs,cp,lo,mid)
    else cmap4_gid(b,span,segs,mid,cp) end

fun cmap12_search {n:nat} .<n>. (
  n: int(n), b: !Buf, span: SfntSpan, cp: int, lo: int, hi: int
): int =
  if ige(lo,hi) then 0 else if n = 0 then search_exhausted() else let
    val mid = iadd(lo,idiv(isub(hi,lo),2))
    val at = iadd(span.offset,iadd(16,imul(mid,12)))
    val start = sfnt_be32(b,at)
    val finish = sfnt_be32(b,iadd(at,4))
  in if ilt(cp,start) then cmap12_search(n-1,b,span,cp,lo,mid)
    else if igt(cp,finish) then cmap12_search(n-1,b,span,cp,iadd(mid,1),hi)
    else iadd(sfnt_be32(b,iadd(at,8)),isub(cp,start)) end

implement sfnt_map(b,info,cp) =
  if ilt(cp,0) orelse igt(cp,1114111) orelse (ige(cp,55296) andalso ile(cp,57343)) then 0
  else case+ info.cmap of
  | Cmap4(span,n) => if igt(cp,65535) then 0 else cmap4_search(airlock_nat(iadd(n,1)),b,span,n,cp,0,n)
  | Cmap12(span,n) => cmap12_search(airlock_nat(iadd(n,1)),b,span,cp,0,n)

extern fun bad_glyph(): int = "mac#anth_die_int"

implement sfnt_metrics(b,info,gid) =
  if ilt(gid,0) orelse ige(gid,info.glyphs) then @{advance=bad_glyph(),bearing=0}
  else let
    val h = imin(gid,isub(info.hmetrics,1))
    val advance = sfnt_be16(b,iadd(info.hmtx.offset,imul(h,4)))
    val bp = if ilt(gid,info.hmetrics) then iadd(imul(gid,4),2)
      else iadd(imul(info.hmetrics,4),imul(isub(gid,info.hmetrics),2))
  in @{advance=advance,bearing=sfnt_signed16(b,iadd(info.hmtx.offset,bp))} end

implement sfnt_glyph(face,cp) = let val+ SfntFace(b,info) = face in sfnt_map(b,info,cp) end
implement sfnt_glyph_metrics(face,gid) = let val+ SfntFace(b,info) = face in sfnt_metrics(b,info,gid) end
