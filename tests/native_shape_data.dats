#include "native_shape_test.hats"
(* Test fixtures keep a distinct generated module from production data ownership. *)
fun joining(db: UnicodeDb,category: PropertyMap(6),ignored: PropertyMap(8)): Option_vt(NativeShapeData) =
  case+ property_load(c_argv(4),JoiningProperty()) of
    | ~PropertyLoaded(j) => Some_vt(NativeShapeData(db,category,ignored,j))
    | ~PropertyRejected(e) => let val ()=unicode_dispose(db) and ()=property_dispose(category) and ()=property_dispose(ignored)
      in None_vt() end
fun ignored(db: UnicodeDb,category: PropertyMap(6)): Option_vt(NativeShapeData) =
  case+ property_load(c_argv(7),IgnorableProperty()) of
    | ~PropertyLoaded(i) => joining(db,category,i)
    | ~PropertyRejected(e) => let val ()=unicode_dispose(db) and ()=property_dispose(category) in None_vt() end
fun category(db: UnicodeDb): Option_vt(NativeShapeData) = case+ property_load(c_argv(6),CategoryProperty()) of
  | ~PropertyLoaded(c) => ignored(db,c) | ~PropertyRejected(e) => let val ()=unicode_dispose(db) in None_vt() end
implement native_test_data() = case+ unicode_load(c_argv(3)) of
  | ~UnicodeDataError() => None_vt() | ~UnicodeLoaded(db) => category(db)
implement native_test_masks() = @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
implement native_test_request(profile) = case+ profile of
  | ShapeCommonHorizontal() => @{profile=profile,script= @{code=1818326126},language=ShapeDefaultLanguage(),direction=ShapeLTR()}
  | ShapeArabicHorizontal() => @{profile=profile,script= @{code=1634885986},language=ShapeDefaultLanguage(),direction=ShapeRTL()}
