datatype ArabicJoining = JoinNone | JoinRight | JoinLeft | JoinDual | JoinCausing | JoinTransparent
(* Boundary neighbours are already the nearest non-transparent scalar.
   Transparent is deliberately absent from this capability. *)
datatype ArabicBoundary = BoundaryNone | BoundaryRight | BoundaryLeft | BoundaryDual | BoundaryCausing
typedef ArabicContext = @{before=ArabicBoundary,after=ArabicBoundary}
datatype ArabicForm = FormNone | FormIsolated | FormInitial | FormMedial | FormFinal
datatype ArabicJoinState = JoinStart | JoinBlocked | JoinOpenIsolated | JoinOpenFinal
datatype ArabicAdvance = RetainPrevious | ReplacePrevious
typedef ArabicJoinStep = @{state=ArabicJoinState,previous=ArabicForm,current=ArabicForm,advance=ArabicAdvance}
typedef ArabicMaskFields = @{initial=uint,medial=uint,final=uint,isolated=uint}
typedef ArabicMaskInfo = @{fields=ArabicMaskFields,all=uint}
datatype ArabicMaskError = ArabicMaskMultipleBits | ArabicMaskOverlap
datavtype ArabicMaskPlan = ArabicMaskPlan of ArabicMaskInfo
datavtype ArabicMaskRead = ArabicMaskAccepted of ArabicMaskPlan | ArabicMaskRejected of ArabicMaskError
