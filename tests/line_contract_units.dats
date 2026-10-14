#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/unicode_db.sats"
staload "data_text/line_types.sats"
staload "data_text/line_engine.sats"
staload "data_text/line_break_map.sats"
staload "line_contracts.sats"

fun copy {n:nat} .<n>. (n: int(n),b: !Buf,s: string,i: int): void =
  if n = 0 then () else let val ()=buf_set(b,i,c_str_byte(s,i)) in copy(n-1,b,s,iadd(i,1)) end

fun fixture(s: string): DecodeResult = let
  val n=c_strlen(s)
  val source=buf_make(n)
  val ()=copy(airlock_nat(n),source,s,0)
  val result=text_decode(source,n)
  val ()=buf_free(source)
in result end

fun differences {n:nat} .<n>. (n: int(n),map: !LineBreakMap,want: string,i: int,errors: int): int =
  if n = 0 then errors else let
    val got=line_break_code(line_break_at(map,i))
    val expected=isub(c_str_byte(want,i),48)
  in differences(n-1,map,want,iadd(i,1),iadd(errors,if ieq(got,expected) then 0 else 1)) end

fun check(map: !PropertyMap(4),width: !PropertyMap(5),category: !PropertyMap(6),
  db: !UnicodeDb,s: string,want: string): int = case+ fixture(s) of
  | ~InvalidTextSpan() => 1
  | ~DecodedText(text) => let
    val n=scalar_count(text)
    val actual=line_boundaries(map,width,category,db,text)
    val errors=differences(airlock_nat(iadd(n,1)),actual,want,0,0)
    val ()=line_breaks_dispose(actual)
    val ()=scalar_dispose(text)
    val ()=if igt(errors,0) then println!("event=line_contract expected=",want," errors=",errors) else ()
  in iadd(errors,if ieq(c_strlen(want),iadd(n,1)) then 0 else 1) end

implement line_contract_units(map,width,category,db) = let
  val baseline=mem_live()
  val a=check(map,width,category,db,"","2")
  val b=check(map,width,category,db,"a\r\nb","00022")
  val c=check(map,width,category,db,"a\nb","0022")
  val d=check(map,width,category,db,"a\013b","0022")
  val e=check(map,width,category,db,"ab","0022")
  val f=check(map,width,category,db,"a b","0022")
  val g=check(map,width,category,db,"a b","0022")
  val h=check(map,width,category,db,"a b","0012")
  val i=check(map,width,category,db,"a b","0002")
  val j=check(map,width,category,db,"a⁠b","0002")
  val k=check(map,width,category,db,"a​b","0012")
  val l=check(map,width,category,db,"اَب","0002")
  val m=check(map,width,category,db,"Şİ","00002")
  val o=check(map,width,category,db,"🇹🇷🇦🇿","00102")
  val q=check(map,width,category,db,"👩‍💻","0002")
in iadd(a+b+c+d+e+f+g+h+i+j+k+l+m+o+q,if ieq(mem_live(),baseline) then 0 else 1) end
