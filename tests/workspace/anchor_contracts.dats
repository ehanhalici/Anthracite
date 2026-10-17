#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/document/doc_anchor.sats"
fun bytes(text: string): Buf = let var buffer=buf_make(c_strlen(text))
  fun fill{n:nat} .<n>. (left: int(n),b: !Buf,i: int): void =
    if left = 0 then () else let val ()=buf_set(b,i,c_str_byte(text,i)) in fill(left-1,b,iadd(i,1)) end
  val length=c_strlen(text) val ()=fill(airlock_nat(length),buffer,0) val ()=buf_set_len(buffer,length)
in buffer end
fun expect(d: !Doc,label: string,first: int,last: int): int = let
  val anchor=bytes(label) val target=doc_resolve_anchor(d,anchor) val ()=buf_free(anchor)
  val finish: int=if last < doc_nlines(d) then doc_line_start(d,last) else doc_len(d)
  val start: int=doc_line_start(d,first)
  val correct=target.found andalso ieq(target.start,start)
    andalso ile(target.finish,finish) andalso igt(target.finish,doc_line_start(d,isub(last,1)))
  val actual_start: int=target.start val actual_finish: int=target.finish val found: bool=target.found
  val ()=if correct then () else println!("event=anchor_mismatch label=",label," start=",actual_start," finish=",actual_finish)
in if correct then 0 else 1 end
fun missing(d: !Doc,label: string): int = let val anchor=bytes(label)
  val target=doc_resolve_anchor(d,anchor) val ()=buf_free(anchor)
in if target.found then 1 else 0 end
fun changes(d: !Doc): int = let val inserted=bytes("intro\n\n") val length=buf_len(inserted)
  val ()=doc_set_caret_move(d,0) val ()=doc_insert_buf(d,inserted,length) val ()=buf_free(inserted)
in expect(d,"^abc",5,7)+expect(d,"Same",4,18) end
fun cases(d: !Doc): int = let
  val source=bytes("literal Same\n\n# Same\nline one\nline two ^abc\n\nOther\ntext ^abcd\n\nmulti one\nmulti two\n\n^stand\n\n## Child\ninside\n# Next\nend\n```\ncode ^fake\n```\n")
  val length=buf_len(source) val ()=doc_insert_buf(d,source,length) val ()=buf_free(source)
  val blocks=expect(d,"^abc",3,5)+expect(d,"^abcd",6,8)+expect(d,"^stand",9,11)
  val headings=expect(d,"Same",2,16)+expect(d,"Child",14,16)
  val rejected=missing(d,"^ab")+missing(d,"^fake")+missing(d,"Sam")
in blocks+headings+rejected+changes(d) end
implement main0() = let val before=mem_live() val document=doc_open()
  val errors=cases(document) val ()=doc_free(document) val balanced=ieq(before,mem_live())
  val ()=println!("event=anchor_contracts errors=",errors," balanced=",balanced)
in if igt(errors,0) orelse not(balanced) then exit(1) else () end
