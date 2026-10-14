#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/opentype_classdef.sats"
staload "data_font/ot_context_header.sats"
fun read_class(b: !Buf,info: OtContextInfo,field: int): OtClassRead = let
  val child=ot_optional_child(info.span,ot_u16(b,info.span,field),info.floor)
in case+ child.kind of
  | ChildMissing() => ClassRejected(ot_error(OtBounds(),info.span))
  | ChildInvalid() => ClassRejected(ot_error(OtBounds(),info.span))
  | ChildPresent() => ot_classdef_parse(b,child.span,info.glyphs) end
fun with_input(info: OtContextInfo,c: OtClassInfo): OtContextInfo = let
  var output: OtContextInfo=info val ()=output.inputClass := c in output end
fun with_back(info: OtContextInfo,c: OtClassInfo): OtContextInfo = let
  var output: OtContextInfo=info val ()=output.backClass := c in output end
fun with_look(info: OtContextInfo,c: OtClassInfo): OtContextInfo = let
  var output: OtContextInfo=info val ()=output.lookClass := c in output end
fun look(b: !Buf,info: OtContextInfo): OtContextHeaderRead = case+ read_class(b,info,8) of
  | ~ClassRejected(e) => ContextHeaderRejected(e)
  | ~ClassAccepted(c) => ContextHeaderAccepted(with_look(info,c))
fun back(b: !Buf,info: OtContextInfo): OtContextHeaderRead = case+ read_class(b,info,4) of
  | ~ClassRejected(e) => ContextHeaderRejected(e) | ~ClassAccepted(c) => look(b,with_back(info,c))
fun input_field(mode: OtContextMode): int = case+ mode of | ContextPlain() => 4 | ContextChained() => 6
implement ot_context_classes(b,info) = case+ read_class(b,info,input_field(info.mode)) of
  | ~ClassRejected(e) => ContextHeaderRejected(e) | ~ClassAccepted(c) => let val out=with_input(info,c) in
    case+ info.mode of
    | ContextPlain() => ContextHeaderAccepted(out) | ContextChained() => back(b,out) end
