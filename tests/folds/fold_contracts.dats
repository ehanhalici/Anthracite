#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/folding/fold_region.sats"

fun check_lines{n:nat} .<n>. (
  remaining: int(n),hidden: !Buf,line: int,owner: int,finish: int
): int =
  if remaining > 0 then let
    val expected=if igt(line,owner) andalso ilt(line,finish) then 1 else 0
    val error=if ieq(fold_region_line_hidden(hidden,line),expected) then 0 else 1
  in iadd(error,check_lines(remaining-1,hidden,iadd(line,1),owner,finish)) end else 0

fun check_one(d: !Doc,regions: !Buf,index: int): int = let
  val owner=fold_region_owner(regions,index)
  val finish=fold_region_end(regions,index)
  val offset=fold_region_offset(regions,index)
  var hidden: Buf=buf_make(1)
  val ()=fold_add(d,offset)
  val ()=fold_regions_compute_hidden(d,regions,hidden)
  val folded=check_lines(airlock_nat(doc_nlines(d)),hidden,0,owner,finish)
  val ()=fold_del(d,offset)
  val ()=fold_regions_compute_hidden(d,regions,hidden)
  val opened=check_lines(airlock_nat(doc_nlines(d)),hidden,0,~1,0)
  val ()=buf_free(hidden)
  val ()=println!("region owner=",owner," end=",finish," kind=",fold_region_kind(regions,index))
in iadd(folded,opened) end

fun check_regions{n:nat} .<n>. (remaining: int(n),d: !Doc,regions: !Buf,index: int): int =
  if remaining > 0 then iadd(check_one(d,regions,index),check_regions(remaining-1,d,regions,iadd(index,1)))
  else 0

fun run(path: string): int = let
  val before=mem_live()
  val d=doc_open()
  val loaded=doc_load(d,path)
  var regions: Buf=buf_make(1)
  val count=fold_region_build(d,regions)
  val errors=check_regions(airlock_nat(count),d,regions,0)
  val ()=buf_free(regions)
  val ()=doc_free(d)
  val health=if loaded andalso ieq(before,mem_live()) then 0 else 1
in iadd(errors,health) end

implement main0() =
  if ine(c_argc(),2) then exit(2) else let
    val errors=run(c_argv(1))
    val ()=println!("event=fold_contracts errors=",errors)
  in if igt(errors,0) then exit(1) else () end
