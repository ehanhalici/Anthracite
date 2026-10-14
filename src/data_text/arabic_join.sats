staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
fun arabic_joining_of(code: int): ArabicJoining
fun arabic_joining(map: !PropertyMap(3),scalar: int): ArabicJoining
fun arabic_boundary_of(joining: ArabicJoining): Option_vt(ArabicBoundary)
fun arabic_join_start(boundary: ArabicBoundary): ArabicJoinState
fun arabic_join_step(state: ArabicJoinState,joining: ArabicJoining): ArabicJoinStep
fun arabic_join_end(state: ArabicJoinState,boundary: ArabicBoundary): ArabicForm
(* Zero disables an unavailable feature. Nonzero masks are one bit each and
   mutually disjoint; no stage may accidentally share another form's mask. *)
fun arabic_mask_plan(fields: ArabicMaskFields): ArabicMaskRead
fun arabic_mask_info(plan: !ArabicMaskPlan): ArabicMaskInfo
fun arabic_form_mask(plan: !ArabicMaskPlan,form: ArabicForm): uint
fun arabic_mask_dispose(plan: ArabicMaskPlan): void
