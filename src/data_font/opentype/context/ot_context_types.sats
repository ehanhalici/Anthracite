staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
datatype OtContextMode = ContextPlain | ContextChained
datatype OtContextEncoding = ContextGlyphs | ContextClasses | ContextCoverages
typedef OtContextPattern = @{span=OtSpan,backAt=int,backCount=int,inputAt=int,inputCount=int,
  lookAt=int,lookCount=int,actionsAt=int,actionCount=int}
datavtype OtContextPatternRead = PatternAccepted of OtContextPattern | PatternRejected of OtError
typedef OtContextInfo = @{span=OtSpan,mode=OtContextMode,encoding=OtContextEncoding,
  setHeader=int,setCount=int,floor=int,glyphs=int,lookups=int,backClass=OtClassInfo,
  inputClass=OtClassInfo,lookClass=OtClassInfo,pattern=OtContextPattern}
datavtype OtContextProgram(kind:int) =
  | {n:nat} OtContextProgram(kind) of (OtContextInfo,OtLayoutDomain(kind),OtCoverageCache(n,n))
datavtype OtContextRead(kind:int) = ContextAccepted(kind) of OtContextProgram(kind) | ContextRejected(kind) of OtError
typedef OtContextMatch(kind:int) = @{domain=OtLayoutDomain(kind),matched=bool,
  inputCount=int,actions=OtSpan,actionCount=int,rule=int}
typedef OtContextAction(kind:int) = @{domain=OtLayoutDomain(kind),position=int,lookup=int}
typedef OtContextLimits = @{back=int,input=int,look=int}
