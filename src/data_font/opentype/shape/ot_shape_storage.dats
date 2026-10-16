#include "data_font/opentype/shape/ot_shape_internal.hats"
implement ot_shape_schedule_make(count,font,glyphs) = let
  val n=airlock_nat(count)
  val empty: OtShapeLookup= @{lookup=0,stage=ShapeVariation(),selection= @{kind=GlyphAll(),mask=0u}}
  val rows=arrayptr_make_elt<OtShapeLookup>(i2sz(n),empty)
in OtShapeSchedule(rows,n,@{font=font,glyphs=glyphs,count=count}) end
implement ot_shape_schedule_info(s) = let val+ OtShapeSchedule(rows,n,info)=s in info end
implement ot_shape_schedule_at(s,index) = let val+ OtShapeSchedule(rows,n,info)=s
in arrayptr_get_at<OtShapeLookup>(rows,i2sz(airlock_below(index,n))) end
implement ot_shape_schedule_set(s,index,row) = let val+ OtShapeSchedule(rows,n,info)=s
in arrayptr_set_at<OtShapeLookup>(rows,i2sz(airlock_below(index,n)),row) end
implement ot_shape_schedule_dispose(s) = let val+ ~OtShapeSchedule(rows,n,info)=s in arrayptr_free(rows) end
