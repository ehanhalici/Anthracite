#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_text/utf8/utf8.sats"
staload "ui_workspace/render/ui_render.sats"
staload "ui_workspace/common/ui_common.sats"

fun same{n:nat} .<n>. (left: int(n),b: !Buf,text: string,i: int): bool =
  if left = 0 then true else ieq(buf_get(b,i),c_str_byte(text,i)) andalso same(left-1,b,text,iadd(i,1))
fun valid(b: !Buf): bool = case+ text_decode(b,buf_len(b)) of
  | ~InvalidTextSpan() => false | ~DecodedText(scalars) => let
    val errors=scalar_errors(scalars) val ()=scalar_dispose(scalars)
  in ieq(errors,0) end
fun matches(b: !Buf,expected: string): bool = let val length=c_strlen(expected)
in ieq(buf_len(b),length) andalso same(airlock_nat(length),b,expected,0) andalso valid(b) end
fun check(source: string,expected: string): int = let
  val d=doc_open() var input=buf_make(0) var output=buf_make(0)
  val ()=buffer_append_string(input,source) val n=buf_len(input)
  val ()=doc_insert_buf(d,input,n) val ()=buffer_append_string(output,"prefix:")
  val ()=math_append_preview(d,0,n,output) val ok=matches(output,expected)
  val ()=doc_free(d) val ()=buf_free(input) val ()=buf_free(output)
in if ok then 0 else 1 end
implement main0() = let
  val before=mem_live()
  val errors=check("x^{∞}+y_{İ}","prefix:x^∞+y_İ")
    +check("q^𝛼+r_ب","prefix:q^𝛼+r_ب")+check("x^2+y_1","prefix:x²+y₁")
    +check("x^{∞","prefix:x^∞")+check("","prefix:")
    +check("\\sqrt{x^2}+\\alpha+\\frac{a}{b}","prefix:√(x²)+α+(a) / (b)")
  val balanced=ieq(before,mem_live())
  val ()=println!("event=math_preview errors=",errors," balanced=",balanced)
in if igt(errors,0) orelse not(balanced) then exit(1) else () end
