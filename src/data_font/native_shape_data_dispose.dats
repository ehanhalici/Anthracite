#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/native_shape_types.sats"
staload "data_font/native_shape.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
implement native_shape_data_dispose(data) = let val+ ~NativeShapeData(db,category,ignored,joining)=data
  val ()=unicode_dispose(db) and ()=property_dispose(category) and ()=property_dispose(ignored)
in property_dispose(joining) end
