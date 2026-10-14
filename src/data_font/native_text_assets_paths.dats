#include "data_font/native_text_assets_internal.hats"
datatype AssetRoot = GeneratedAssetRoot | SourceAssetRoot
typedef AssetPath = @{root=AssetRoot,name=string}
fun file(kind: NativeAssetKind): AssetPath = case+ kind of
  | AssetGrapheme() => @{root=GeneratedAssetRoot(),name="unicode18.bin"}
  | AssetCategory() => @{root=GeneratedAssetRoot(),name="unicode18-category.bin"}
  | AssetIgnorable() => @{root=GeneratedAssetRoot(),name="unicode18-ignorable.bin"}
  | AssetJoining() => @{root=GeneratedAssetRoot(),name="unicode18-joining.bin"}
  | AssetNormalization() => @{root=GeneratedAssetRoot(),name="unicode18-normalization.bin"}
  | AssetModifierMarks() => @{root=GeneratedAssetRoot(),name="unicode18-modifier-mark.bin"}
  | AssetScripts() => @{root=GeneratedAssetRoot(),name="unicode18-script.bin"}
  | AssetExtensions() => @{root=GeneratedAssetRoot(),name="unicode18-script-extensions.bin"}
  | AssetBidi() => @{root=GeneratedAssetRoot(),name="unicode18-bidi.bin"}
  | AssetBrackets() => @{root=SourceAssetRoot(),name="BidiBrackets.txt"}
  | AssetMirrors() => @{root=SourceAssetRoot(),name="BidiMirroring.txt"}
  | AssetWords() => @{root=GeneratedAssetRoot(),name="unicode18-word.bin"}
  | AssetLines() => @{root=GeneratedAssetRoot(),name="unicode18-line.bin"}
  | AssetEastAsian() => @{root=GeneratedAssetRoot(),name="unicode18-east-asian.bin"}
fun copy{n:nat} .<n>. (left: int(n),text: string,b: !Buf,index: int,offset: int): void =
  if left = 0 then () else let val ()=buf_set(b,iadd(offset,index),c_str_byte(text,index))
  in copy(left-1,text,b,iadd(index,1),offset) end
implement native_asset_path(location,kind) = let val path=file(kind)
  val root: string=case+ path.root of | GeneratedAssetRoot() => location.generated | SourceAssetRoot() => location.source
  val root_size=c_strlen(root) and size=c_strlen(path.name) val offset=if igt(root_size,0) then iadd(root_size,1) else 0
  val b=buf_make(iadd(iadd(offset,size),1)) val ()=copy(airlock_nat(root_size),root,b,0,0)
  val ()=if igt(root_size,0) then buf_set(b,root_size,47) else ()
  val ()=copy(airlock_nat(size),path.name,b,0,offset) val ()=buf_set_len(b,iadd(offset,size))
in b end
implement native_asset_error(kind) = @{asset=kind,reason=AssetData(),detail=0}
