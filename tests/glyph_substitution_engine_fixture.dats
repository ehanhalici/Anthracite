#include "glyph_substitution_engine_test.hats"
extern fun substitution_engine_parse_failed(): OtSubstitutionGraph = "mac#anth_die_box"
implement substitution_engine_fixture(first,second,third) = let
  val a=ot_fixture_words(first) and c=ot_fixture_words(second) and d=ot_fixture_words(third)
  val b=substitution_cache_fixture(a,c,d)
  val ()=buf_free(a) and ()=buf_free(c) and ()=buf_free(d)
in b end
implement substitution_engine_parse(b) = case+ substitution_cache_parse(b) of
  | ~SubstitutionGraphRejected(e) => substitution_engine_parse_failed() | ~SubstitutionGraphAccepted(g) => g
implement substitution_engine_take(result,expected,errors) = let
  val+ ~GlyphPassResult(run,status,visited,matches)=result
  val ()=if reverse_pass_ready(status) andalso ieq(expected,matches) then () else let
    val ()=println!("event=substitution_test expected_matches=",expected," actual_matches=",matches,
      " ready=",reverse_pass_ready(status))
  in errors := iadd(errors,1) end
in run end
