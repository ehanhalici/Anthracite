#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/sfnt.sats"
staload "font_fixture.sats"

implement fixture_put16(b,p,v) = let
  val () = buf_set(b,p,imod(idiv(v,256),256))
in buf_set(b,iadd(p,1),imod(v,256)) end

implement fixture_put32(b,p,v) = let
  val () = fixture_put16(b,p,idiv(v,65536))
in fixture_put16(b,iadd(p,2),imod(v,65536)) end

fun directory_record(b: !Buf, i: int, table: SfntTable, at: int, bytes: int): void = let
  val p = iadd(12,imul(i,16))
  val () = fixture_put32(b,p,sfnt_table_code(table))
  val () = fixture_put32(b,iadd(p,8),at)
in fixture_put32(b,iadd(p,12),bytes) end

fun fixture_directory(b: !Buf): void = let
  val () = fixture_put32(b,0,65536)
  val () = fixture_put16(b,4,7)
  val () = directory_record(b,0,TableCmap(),124,64)
  val () = directory_record(b,1,TableGlyf(),188,0)
  val () = directory_record(b,2,TableHead(),188,54)
  val () = directory_record(b,3,TableHhea(),244,36)
  val () = directory_record(b,4,TableHmtx(),280,10)
  val () = directory_record(b,5,TableLoca(),292,8)
in directory_record(b,6,TableMaxp(),300,32) end

fun fixture_metrics(b: !Buf): void = let
  val () = fixture_put32(b,188,65536)
  val () = fixture_put32(b,200,1594834165)
  val () = fixture_put16(b,206,1000)
  val () = fixture_put32(b,244,65536)
  val () = fixture_put16(b,248,800)
  val () = fixture_put16(b,250,65336)
  val () = fixture_put16(b,278,2)
  val () = fixture_put16(b,280,500)
  val () = fixture_put16(b,286,65516)
  val () = fixture_put16(b,288,30)
  val () = fixture_put32(b,300,65536)
in fixture_put16(b,304,3) end

fun fixture_cmap_header(b: !Buf, encoding: int): void = let
  val () = fixture_put16(b,126,1)
  val () = fixture_put16(b,128,3)
  val () = fixture_put16(b,130,encoding)
in fixture_put32(b,132,12) end

fun fixture_cmap4(b: !Buf): void = let
  val () = fixture_cmap_header(b,1)
  val () = fixture_put16(b,136,4)
  val () = fixture_put16(b,138,32)
  val () = fixture_put16(b,142,4)
  val () = fixture_put16(b,150,65)
  val () = fixture_put16(b,152,65535)
  val () = fixture_put16(b,156,65)
  val () = fixture_put16(b,158,65535)
  val () = fixture_put16(b,160,65472)
in fixture_put16(b,162,1) end

fun fixture_cmap12(b: !Buf): void = let
  val () = fixture_cmap_header(b,10)
  val () = fixture_put16(b,136,12)
  val () = fixture_put32(b,140,40)
  val () = fixture_put32(b,148,2)
  val () = fixture_put32(b,152,65)
  val () = fixture_put32(b,156,65)
  val () = fixture_put32(b,160,1)
  val () = fixture_put32(b,164,128512)
  val () = fixture_put32(b,168,128512)
in fixture_put32(b,172,2) end

implement fixture_font(map) = let
  val b = buf_make(352)
  val () = fixture_directory(b)
  val () = fixture_metrics(b)
  val () = case+ map of | Fixture4() => fixture_cmap4(b) | Fixture12() => fixture_cmap12(b)
  val () = buf_set_len(b,332)
in b end

fun composite_outline(b: !Buf): void = let
  val () = fixture_put16(b,332,65535)
  val () = fixture_put16(b,342,35)
  val () = fixture_put16(b,344,2)
  val () = fixture_put16(b,350,1)
  val () = fixture_put16(b,352,2)
in fixture_put16(b,354,2) end

fun simple_outline(b: !Buf): void = let
  val () = fixture_put16(b,358,1)
  val () = fixture_put16(b,364,100)
  val () = fixture_put16(b,366,100)
  val () = fixture_put16(b,368,3)
  val () = buf_set(b,372,1)
  val () = buf_set(b,373,1)
  val () = buf_set(b,374,1)
  val () = buf_set(b,375,1)
  val () = fixture_put16(b,378,100)
  val () = fixture_put16(b,382,65436)
in fixture_put16(b,388,100) end

implement fixture_outline_font() = let
  var b = fixture_font(Fixture4())
  val () = buf_resize(b,392)
  val () = fixture_put32(b,36,332)
  val () = fixture_put32(b,40,60)
  val () = fixture_put16(b,296,13)
  val () = fixture_put16(b,298,30)
  val () = composite_outline(b)
  val () = simple_outline(b)
  val () = buf_set_len(b,392)
in b end
