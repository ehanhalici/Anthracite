#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
staload "data_font/opentype/substitution/gsub_reverse.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_reverse_contracts.sats"

fun filled(): int = let
  val c=ot_cov_cache_make(2)
  val info: OtCoverageInfo= @{span= @{offset=8,length=6},encoding=OtList(),count=1,total=1}
  val d=ot_cov_cache_append(c,info)
  val e=ot_cov_cache_append(d,info)
  val first=ot_cov_cache_get(e,0)
  val second=ot_cov_cache_get(e,1)
  val ok=ieq(first.span.offset,8) andalso ieq(second.total,1)
  val ()=ot_cov_cache_dispose(e)
in if ok then 0 else 1 end
fun invalid_fields(): int = let
  val b=reverse_fixture()
  val fields=buf_make(4)
  val ()=buf_set32(fields,0,SIGNED_INT_MAX_VALUE)
  val ()=buf_set_len(fields,4)
  val errors: int=case+ ot_cov_cache_read(b,ot_fixture_span(b),fields,20,10) of
    | ~CoverageCacheRejected(e) => 0
    | ~CoverageCacheAccepted(c) => let val ()=ot_cov_cache_dispose(c) in 1 end
  val ()=buf_free(fields) and ()=buf_free(b)
in errors end
fun unfinished(): int = let
  val c=ot_cov_cache_make(2)
  val info: OtCoverageInfo= @{span= @{offset=8,length=6},encoding=OtList(),count=1,total=1}
  val d=ot_cov_cache_append(c,info)
  val ()=ot_cov_cache_dispose(d)
in 0 end
implement reverse_test_cache() = filled()+unfinished()+invalid_fields()
