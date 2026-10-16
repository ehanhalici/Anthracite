#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_font/opentype/features/ot_feature_params_kind.sats"

(* Big-endian packed tags: 'size' = 0x73697A65, 'ss' prefix = 0x7373,
   'cv' prefix = 0x6376. Digits are ASCII 48..57. *)
fun size_code(): int = 1936292453
fun stylistic_prefix(): int = 29555
fun variant_prefix(): int = 25462
fun byte_at(code: int, place: int): int = imod(idiv(code,place),256)
fun is_digit(v: int): bool = ige(v,48) andalso ile(v,57)
fun tens_units(code: int): int = iadd(imul(10,isub(byte_at(code,256),48)),isub(byte_at(code,1),48))
fun digits_valid(code: int): bool = is_digit(byte_at(code,256)) andalso is_digit(byte_at(code,1))
fun numbered(code: int, leading: int, lo: int, hi: int): bool =
  if not(ieq(idiv(code,WORD16_MODULUS),leading)) then false
  else if not(digits_valid(code)) then false
  else let val n=tens_units(code) in ige(n,lo) andalso ile(n,hi) end

implement ot_params_kind_of(tag) = let val c=tag.code in
  if ieq(c,size_code()) then ParamsKindSize()
  else if numbered(c,stylistic_prefix(),1,20) then ParamsKindStylistic()
  else if numbered(c,variant_prefix(),1,99) then ParamsKindVariant()
  else ParamsKindOpaque() end
