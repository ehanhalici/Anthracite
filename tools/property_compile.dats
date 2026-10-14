#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_text/unicode_property.sats"
staload "data_text/property_source.sats"
staload "data_text/property_writer.sats"

fun domain_of(name: string): Option_vt(AnyPropertyDomain) =
  if ieq(c_strcmp(name,"word"),0) then Some_vt(WordProperty())
  else if ieq(c_strcmp(name,"bidi"),0) then Some_vt(BidiProperty())
  else if ieq(c_strcmp(name,"joining"),0) then Some_vt(JoiningProperty())
  else if ieq(c_strcmp(name,"line"),0) then Some_vt(LineProperty())
  else if ieq(c_strcmp(name,"east-asian"),0) then Some_vt(EastAsianProperty())
  else if ieq(c_strcmp(name,"category"),0) then Some_vt(CategoryProperty())
  else if ieq(c_strcmp(name,"ignorable"),0) then Some_vt(IgnorableProperty())
  else if ieq(c_strcmp(name,"modifier-mark"),0) then Some_vt(ModifierMarkProperty()) else None_vt()

fun compile{kind:int}(domain: PropertyDomain(kind)): bool = let
  val dense = buf_make(imul(UNICODE_SCALAR_LIMIT,4))
  val loaded = property_source_read(domain,c_argv(2),dense)
  val ok = loaded andalso property_write(domain,dense,c_argv(3))
  val () = buf_free(dense)
in ok end

implement main0() =
  if ine(c_argc(),4) then exit(2) else case+ domain_of(c_argv(1)) of
  | ~None_vt() => exit(2) | ~Some_vt(domain) => if compile(domain) then () else exit(1)
