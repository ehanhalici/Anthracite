staload "mem.sats"
staload "data_text/script/script_types.sats"
datatype ScriptItemsStatus = ScriptItemsReady | ScriptItemsCapacity
datavtype ScriptItems = ScriptItems of (Buf,int)
datavtype ScriptItemsRead = ScriptItemsAccepted of ScriptItems | ScriptItemsRejected of ScriptItemsStatus
(* A single owner per operation; no per-scalar/cluster/punctuation allocation. *)
datavtype ScriptItemsWorkspace = ScriptItemsWorkspace of (Buf,Buf,Buf,Buf,Buf,int)
typedef ScriptItemsState = @{start=int,count=int,preferred=ScriptCode,depth=int}
typedef ScriptCluster = @{first=int,finish=int,set=ScriptSet}
typedef ScriptPair = @{opening=int,depth=int}
typedef ScriptCandidate = @{count=int,preferred=ScriptCode,valid=bool}
