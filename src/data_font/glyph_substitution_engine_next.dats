#include "data_font/glyph_substitution_engine_internal.hats"
extern fun substitution_next_failed(): int = "mac#anth_die_int"
fun walk{n,f:nat} .<f>. (left: int(f),s: !GlyphStorage(n),meta: GlyphRunMeta,node: int,
  remaining: &int >> int): GlyphContextNode =
  if ieq(node,~1) then @{status=GlyphPassApplied(),node= ~1}
  else if left = 0 then let val failed=substitution_next_failed() in @{status=GlyphPassReference(),node=failed} end
  else if ilt(node,0) orelse ige(node,meta.used) then @{status=GlyphPassReference(),node= ~1} else let
    val links=glyph_storage_links(s,node)
  in case+ links.life of | GlyphLive() => @{status=GlyphPassApplied(),node=node}
    | GlyphVacant() => @{status=GlyphPassReference(),node= ~1}
    | GlyphRemoved() => if ile(remaining,0) then @{status=GlyphPassCapacity(),node= ~1} else let
      val ()=remaining := isub(remaining,1)
    in walk(left-1,s,meta,links.next,remaining) end end
implement glyph_substitution_next(run,node,remaining) = let val+ GlyphRun(phase,meta,s)=run
in walk(airlock_nat(meta.used),s,meta,node,remaining) end
