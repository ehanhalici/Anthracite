staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
datavtype OtPlanRead(kind:int) = PlanAccepted(kind) of OtStagePlan(kind) | PlanRejected(kind) of OtError
fun ot_stage_plan{kind:int}(b: !Buf,table: !OtLayoutTable(kind,0),language: OtChild,set: !OtFeatureSet): OtPlanRead(kind)
(* Later script stages select only explicitly requested features. The script
   scheduler assigns the required feature to one stage, not every stage. *)
fun ot_stage_plan_requested{kind:int}(b: !Buf,table: !OtLayoutTable(kind,0),language: OtChild,set: !OtFeatureSet): OtPlanRead(kind)
fun ot_plan_lookup_count{kind:int}(plan: !OtStagePlan(kind)): int
fun ot_plan_lookup{kind:int}(plan: !OtStagePlan(kind),index: int): int
fun ot_plan_feature_count{kind:int}(plan: !OtStagePlan(kind),index: int): int
fun ot_plan_feature{kind:int}(plan: !OtStagePlan(kind),index: int,owner: int): int
fun ot_plan_dispose{kind:int}(plan: OtStagePlan(kind)): void
fun ot_layout_dispose{kind:int}(table: OtLayoutTable(kind,0)): void
