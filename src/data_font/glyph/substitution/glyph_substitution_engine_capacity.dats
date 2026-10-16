#include "data_font/glyph/substitution/glyph_substitution_engine_internal.hats"
fun limits_valid(limits: OtContextLimits): bool =
  ige(limits.back,0) andalso ile(limits.back,WORD16_MAX_VALUE) andalso ige(limits.input,1) andalso ile(limits.input,WORD16_MAX_VALUE)
    andalso ige(limits.look,0) andalso ile(limits.look,WORD16_MAX_VALUE)
fun budget(run: !GlyphRun(1),limits: OtContextLimits): GlyphSubstitutionCapacity = let
  val columns=g0int2int_int_llint(g0uint2int_size_int(sizeof<GlyphCore>)+g0uint2int_size_int(sizeof<GlyphLinks>)
    +g0uint2int_size_int(sizeof<GlyphPosition>))
  val source=g0int2int_int_llint(glyph_run_capacity(run))*columns
  val window=(g0int2int_int_llint(limits.back)+g0int2int_int_llint(limits.input)+g0int2int_int_llint(limits.look))*8LL
  val ligature=g0int2int_int_llint(limits.input)*12LL
  (* A uint16 Multiple sequence has at most 65,535 outputs. Account for
     the output buffer's power-of-two growth, plus old/new copy overlap. *)
  val remaining=g0int2int_int_llint(MAX_REC_FUEL)-source-window-ligature-65536LL*8LL
  val columnBudget=remaining/2LL and contextBudget=remaining/2LL
  val frameBytes=g0int2int_int_llint(g0uint2int_size_int(sizeof<GlyphSubstitutionFrame>))*2LL
  val rows=columnBudget/(columns*2LL)
  val frames=(contextBudget/2LL)/frameBytes and slots=(contextBudget/2LL)/16LL
in if rows < g0int2int_int_llint(glyph_run_capacity(run)) orelse frames < 1LL orelse slots < 1LL
  then @{status=GlyphPassCapacity(),rows=0,frames=0,slots=0}
  else @{status=GlyphPassApplied(),rows=airlock_i32(rows),frames=airlock_i32(frames),slots=airlock_i32(slots)} end
implement glyph_substitution_capacity(run,limits) =
  if not(limits_valid(limits)) then @{status=GlyphPassReference(),rows=0,frames=0,slots=0} else budget(run,limits)
