staload "mem.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
datavtype NativeTextContexts = {n:pos} NativeTextContexts of
  (arrayptr(ArabicBoundary,n),arrayptr(ArabicBoundary,n),int(n))
datatype NativeContextFailure = ContextCapacity
datavtype NativeContextRead = NativeContextAccepted of NativeTextContexts
  | NativeContextRejected of NativeContextFailure
