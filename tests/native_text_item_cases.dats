#include "data_font/native_text_items_internal.hats"
staload "native_text_item_cases.sats"
datatype ItemCase = ItemEmpty | ItemMixed | ItemCrLf | ItemNormalized | ItemGeneral | ItemStress
fun copy{n:nat} .<n>. (left: int(n),text: string,b: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set(b,index,c_str_byte(text,index))
  in copy(left-1,text,b,iadd(index,1)) end
fun bytes(text: string): Buf = let val n=c_strlen(text) val b=buf_make(n)
  val ()=copy(airlock_nat(n),text,b,0) val ()=buf_set_len(b,n)
in b end
fun boundary(a: !NativeTextAnalysis,index: int): bool =
  ieq(index,native_text_analysis_count(a)) orelse native_text_analysis_grapheme(a,index)
fun member(a: !NativeTextAnalysis,item: NativeTextItem,index: int): bool = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes)=a
  val script=native_text_analysis_script(a,index)
  val key=not(native_text_analysis_grapheme(a,index)) orelse
    (ieq(script.code,item.script.code) andalso ieq(native_text_analysis_level(a,index),item.level))
in key andalso ige(scalar_start(text,index),item.sourceStart) andalso ile(scalar_end(text,index),item.sourceEnd) end
fun members{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,item: NativeTextItem,index: int): bool =
  if left = 0 then true else member(a,item,index) andalso members(left-1,a,item,iadd(index,1))
fun coverage{fuel:nat} .<fuel>. (fuel: int(fuel),a: !NativeTextAnalysis,items: !NativeTextItems,
  row: int,start: int): bool =
  if fuel = 0 then let val dead=native_items_fuel_failed() in false end
  else if ige(row,native_text_items_count(items)) then ieq(start,native_text_analysis_count(a)) else let
    val item=native_text_items_at(items,row) val script=native_text_analysis_script(a,item.start)
    val good=ieq(item.start,start) andalso igt(item.finish,start) andalso boundary(a,item.start)
      andalso boundary(a,item.finish) andalso ieq(item.level,native_text_analysis_level(a,item.start))
      andalso ieq(item.script.code,script.code) andalso ilt(item.sourceStart,item.sourceEnd)
      andalso members(airlock_nat(isub(item.finish,item.start)),a,item,item.start)
  in good andalso coverage(fuel-1,a,items,iadd(row,1),item.finish) end
fun starts{fuel:nat} .<fuel>. (fuel: int(fuel),items: !NativeTextItems,row: int,index: int): bool =
  if fuel = 0 then let val dead=native_items_fuel_failed() in false end
  else if ige(row,native_text_items_count(items)) then false else let val item=native_text_items_at(items,row)
  in ieq(item.start,index) orelse starts(fuel-1,items,iadd(row,1),index) end
fun rtl(item: NativeTextItem): bool = case+ native_text_item_direction(item) of
  | ShapeRTL() => true | ShapeLTR() => false
fun mixed_items(items: !NativeTextItems): bool =
  if ine(native_text_items_count(items),2) then false else let
    val first=native_text_items_at(items,0) val last=native_text_items_at(items,1)
  in ieq(first.finish,7) andalso ieq(last.start,7) andalso ieq(last.finish,10)
    andalso rtl(last) andalso ieq(last.sourceEnd,15) end
fun normalized_items(items: !NativeTextItems): bool =
  if ine(native_text_items_count(items),1) then false else let val item=native_text_items_at(items,0)
  in ieq(item.sourceEnd,7) end
fun expectation(items: !NativeTextItems,kind: ItemCase): bool = case+ kind of
  | ItemEmpty() => ieq(native_text_items_count(items),0)
  | ItemMixed() => mixed_items(items)
  | ItemCrLf() => not(starts(MAX_REC_FUEL,items,0,2)) andalso starts(MAX_REC_FUEL,items,0,3)
  | ItemNormalized() => normalized_items(items)
  | ItemGeneral() => ige(native_text_items_count(items),1)
  | ItemStress() => ieq(native_text_items_count(items),65536)
fun analyzed(a: NativeTextAnalysis,kind: ItemCase): int = let
  val errors=case+ native_text_items_make(a) of | ~NativeItemsRejected(e) => 1
    | ~NativeItemsAccepted(items) => let
      val ok=coverage(MAX_REC_FUEL,a,items,0,0) andalso expectation(items,kind)
      val ()=native_text_items_dispose(items) in if ok then 0 else 1 end
  val ()=native_text_analysis_dispose(a)
in errors end
fun check(assets: !NativeTextAssets,text: string,kind: ItemCase): int = let val source=bytes(text)
  val errors=case+ native_text_analyze(assets,source,buf_len(source),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => analyzed(a,kind)
  val ()=buf_free(source)
in errors end
fun repeated{n:nat} .<n>. (left: int(n),source: !Buf,index: int): void =
  if left = 0 then () else let
    val ()=buf_set(source,index,97) and ()=buf_set(source,iadd(index,1),216)
    val ()=buf_set(source,iadd(index,2),168)
  in repeated(left-1,source,iadd(index,3)) end
fun stress(assets: !NativeTextAssets): int = let val source=buf_make(98304)
  val ()=repeated(32768,source,0) val ()=buf_set_len(source,98304)
  val errors=case+ native_text_analyze(assets,source,buf_len(source),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => analyzed(a,ItemStress())
  val ()=buf_free(source)
in errors end
implement native_text_item_cases(assets) = check(assets,"",ItemEmpty())+check(assets,"Türkçe بَب",ItemMixed())
  +check(assets,"a\r\nb",ItemCrLf())+check(assets,"Ş İ",ItemNormalized())+check(assets,"aَب",ItemGeneral())
  +check(assets,"a ⁧ب1ب⁩z",ItemGeneral())+check(assets,"a 👩‍👩‍👧 b",ItemGeneral())+check(assets,"à̕ ب",ItemGeneral())
  +stress(assets)
