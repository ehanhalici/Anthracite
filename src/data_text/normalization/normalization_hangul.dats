#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_hangul.sats"

macdef HANGUL_SYLLABLE_BASE = 44032
macdef HANGUL_LEADING_BASE = 4352
macdef HANGUL_VOWEL_BASE = 4449
macdef HANGUL_TRAILING_BASE = 4519
macdef HANGUL_LEADING_COUNT = 19
macdef HANGUL_VOWEL_COUNT = 21
macdef HANGUL_TRAILING_COUNT = 28
macdef HANGUL_SYLLABLES_PER_LEADING = HANGUL_VOWEL_COUNT * HANGUL_TRAILING_COUNT
macdef HANGUL_SYLLABLE_LIMIT = HANGUL_SYLLABLE_BASE + HANGUL_LEADING_COUNT * HANGUL_SYLLABLES_PER_LEADING
macdef HANGUL_LEADING_LIMIT = HANGUL_LEADING_BASE + HANGUL_LEADING_COUNT
macdef HANGUL_VOWEL_LIMIT = HANGUL_VOWEL_BASE + HANGUL_VOWEL_COUNT
macdef HANGUL_TRAILING_LIMIT = HANGUL_TRAILING_BASE + HANGUL_TRAILING_COUNT

implement normalization_hangul_syllable(cp) = ige(cp,HANGUL_SYLLABLE_BASE) andalso ilt(cp,HANGUL_SYLLABLE_LIMIT)

implement normalization_hangul_parts(cp) =
  if not(normalization_hangul_syllable(cp)) then @{first=cp,second=0,third=0,count=0} else let
    val index = isub(cp,HANGUL_SYLLABLE_BASE)
    val trailing = imod(index,HANGUL_TRAILING_COUNT)
    val leading = iadd(HANGUL_LEADING_BASE,idiv(index,HANGUL_SYLLABLES_PER_LEADING))
    val vowel = iadd(HANGUL_VOWEL_BASE,idiv(imod(index,HANGUL_SYLLABLES_PER_LEADING),HANGUL_TRAILING_COUNT))
  in @{first=leading,second=vowel,third=iadd(HANGUL_TRAILING_BASE,trailing),count=(if ieq(trailing,0) then 2 else 3)} end

implement normalization_hangul_compose(left,right) =
  if ige(left,HANGUL_LEADING_BASE) andalso ilt(left,HANGUL_LEADING_LIMIT)
    andalso ige(right,HANGUL_VOWEL_BASE) andalso ilt(right,HANGUL_VOWEL_LIMIT) then
    iadd(HANGUL_SYLLABLE_BASE,imul(iadd(imul(isub(left,HANGUL_LEADING_BASE),HANGUL_VOWEL_COUNT),
      isub(right,HANGUL_VOWEL_BASE)),HANGUL_TRAILING_COUNT))
  else if normalization_hangul_syllable(left) andalso ieq(imod(isub(left,HANGUL_SYLLABLE_BASE),HANGUL_TRAILING_COUNT),0)
    andalso igt(right,HANGUL_TRAILING_BASE) andalso ilt(right,HANGUL_TRAILING_LIMIT)
    then iadd(left,isub(right,HANGUL_TRAILING_BASE))
  else ~1

implement normalization_leaf_info(cp) = let
  val parts = normalization_hangul_parts(cp)
  val size = if ieq(parts.count,0) then 1 else parts.count
in @{cp=cp,ccc=0,kind=NoMapping(),offset=0,count=0,depth=(if ieq(parts.count,0) then 0 else 1),
    canonical=size,compatibility=size,excluded=false} end
