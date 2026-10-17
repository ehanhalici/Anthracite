staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
typedef GsubLigatureInfo = @{span=OtSpan,coverage=OtCoverageInfo,count=int,glyphs=int,maximum=int}
datavtype GsubLigatures = GsubLigatures of GsubLigatureInfo
datavtype GsubLigaturesRead = LigaturesAccepted of GsubLigatures | LigaturesRejected of OtError
typedef GsubLigatureResult = @{matched=bool,glyph=int,components=int,rule=int}
datatype GsubLigatureMatchStatus = LigatureHit | LigatureMiss | LigatureBudget
typedef GsubLigatureMatch = @{status=GsubLigatureMatchStatus,result=GsubLigatureResult}
datatype GsubLigatureInputStatus = LigationInputReady | LigationInputBudget
typedef GsubLigatureInputBound = @{maximum=int,status=GsubLigatureInputStatus}
