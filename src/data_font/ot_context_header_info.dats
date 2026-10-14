#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_context_header.sats"
fun empty_class(): OtClassInfo = @{span= @{offset=0,length=0},encoding=OtList(),count=0,first=0,maximum=0}
fun empty_pattern(s: OtSpan): OtContextPattern =
  @{span=s,backAt=0,backCount=0,inputAt=0,inputCount=0,lookAt=0,lookCount=0,actionsAt=0,actionCount=0}
implement ot_context_info(s,mode,encoding,header,count,floor,glyphs,lookups) =
  @{span=s,mode=mode,encoding=encoding,setHeader=header,setCount=count,floor=floor,glyphs=glyphs,
    lookups=lookups,backClass=empty_class(),inputClass=empty_class(),lookClass=empty_class(),pattern=empty_pattern(s)}
