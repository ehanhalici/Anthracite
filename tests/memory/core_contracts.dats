#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/layout/layout.sats"
staload "search/ix_store.sats"

macdef RECORD_COUNT = 17
macdef TEST_CAPACITY_BYTES = 256

fun check(ok: bool): int = if ok then 0 else 1

fun test_word_bytes(): int = let
  val b=buf_make(WORD32_BYTES)
  val ()=buf_set32(b,0,16909060) (* 0x01020304, independent byte-order oracle. *)
  val bytes=ieq(buf_get(b,0),4) andalso ieq(buf_get(b,1),3)
    andalso ieq(buf_get(b,2),2) andalso ieq(buf_get(b,3),1)
  val ()=buf_set32(b,0,~1)
  val signed=ieq(buf_get32(b,0),~1)
  val ()=buf_free(b)
in check(bytes andalso signed) end

fun test_resize_zero(): int = let
  var b: Buf=buf_make(WORD32_BYTES)
  val ()=buf_set32(b,0,37)
  val ()=buf_set_len(b,WORD32_BYTES)
  val ()=buf_ensure(b,TEST_CAPACITY_BYTES)
  val kept=ieq(buf_get32(b,0),37) andalso ieq(buf_len(b),WORD32_BYTES)
  val ()=buf_zero(b)
  val reset=ieq(buf_len(b),0) andalso ieq(buf_get32(b,0),0)
  val ()=buf_set_len(b,WORD32_BYTES)
  val ()=buf_free(b)
in check(kept andalso reset) end

fun fill_layout{n:nat} .<n>. (remaining: int(n),b: &Buf >> _,i: int): void =
  if remaining > 0 then let
    val ()=buf_ensure(b,layout_line_need(i))
    val ()=layout_line_put(b,i,imul(i,3),iadd(i,1),RECORD_COUNT)
  in fill_layout(remaining-1,b,iadd(i,1)) end else ()

fun check_layout{n:nat} .<n>. (remaining: int(n),b: !Buf,i: int): int =
  if remaining > 0 then let
    val ok=ieq(layout_line_y(b,i,RECORD_COUNT),imul(i,3))
      andalso ieq(layout_line_step(b,i,RECORD_COUNT),iadd(i,1))
  in iadd(check(ok),check_layout(remaining-1,b,iadd(i,1))) end else 0

fun test_layout_records(): int = let
  var b: Buf=layout_open()
  val ()=fill_layout(RECORD_COUNT,b,0)
  val ()=buf_ensure(b,layout_node_need(RECORD_COUNT,RECORD_COUNT))
  val ()=layout_node_put_y(b,RECORD_COUNT,91,RECORD_COUNT)
  val ()=layout_node_put_height(b,RECORD_COUNT,23,RECORD_COUNT)
  val errors=check_layout(RECORD_COUNT,b,0)
  val node=ieq(layout_node_y(b,RECORD_COUNT,RECORD_COUNT),91)
    andalso ieq(layout_node_height(b,RECORD_COUNT,RECORD_COUNT),23)
  val ()=layout_cache_store(b,7,11,91,1,43)
  val cache=layout_cache_matches(b,7,11,1) andalso not(layout_cache_matches(b,8,11,1))
    andalso ieq(layout_cache_height(b),91) andalso ieq(layout_wrap(b),43)
  val ()=layout_dispose(b)
in iadd(errors,check(node andalso cache)) end

fun test_index_records(): int = let
  var files: Buf=buf_make(1)
  val first=ix_file_add(files,3,5,7,11,13,17,19,23)
  val second=ix_file_add(files,29,31,37,41,43,47,53,59)
  val ok=ieq(first,0) andalso ieq(second,1) andalso ieq(ix_file_count(files),2)
    andalso ieq(buf_len(files),imul(2,IX_FILE_BYTES))
    andalso ieq(ix_file_get(files,0,IX_F_SYMCOUNT),23)
    andalso ieq(ix_file_get(files,1,IX_F_PATHOFF),29)
  val ()=ix_file_set(files,1,IX_F_STATE,61)
  val isolated=ieq(ix_file_get(files,0,IX_F_STATE),13) andalso ieq(ix_file_get(files,1,IX_F_STATE),61)
  val ()=buf_free(files)
in check(ok andalso isolated) end

fun bloom_bytes{n:nat} .<n>. (remaining: int(n),b: !Buf,i: int): int =
  if remaining > 0 then let
    val ()=ix_bloom_set_trigram(b,0,i,CHAR_LOWER_A,CHAR_LOWER_Z)
    val hit=ix_bloom_test_trigram(b,0,i,CHAR_LOWER_A,CHAR_LOWER_Z)
    val other=ix_bloom_test_trigram(b,1,i,CHAR_LOWER_A,CHAR_LOWER_Z)
  in iadd(check(hit andalso not(other)),bloom_bytes(remaining-1,b,iadd(i,1))) end else 0

fun test_bloom(): int = let
  var b: Buf=buf_make(1)
  val ()=ix_bloom_ensure(b,2)
  val errors=bloom_bytes(256,b,0)
  val ()=buf_free(b)
in errors end

implement main0() = let
  val before=mem_live()
  val memory=iadd(test_word_bytes(),test_resize_zero())
  val records=iadd(test_layout_records(),test_index_records())
  val bloom=test_bloom()
  val ownership=check(ieq(before,mem_live()))
  val errors=iadd(iadd(memory,records),iadd(bloom,ownership))
  val ()=println!("event=core_contracts errors=",errors)
in if igt(errors,0) then exit(1) else () end
