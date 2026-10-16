#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
extern fun glyph_attachment_exhausted(): GlyphAttachmentCheck = "mac#anth_die_box"
fun chain {n,r:nat} .<r>. (remaining: int(r),s: !GlyphStorage(n),meta: GlyphRunMeta,
  node: int,cursor: int): GlyphAttachmentCheck =
  if ieq(cursor,~1) then AttachmentValid() else if ieq(node,cursor) then AttachmentCycle()
  else if remaining = 0 then glyph_attachment_exhausted()
  else if not(glyph_run_node(s,meta,cursor)) then AttachmentInvalid() else let
    val p=glyph_storage_position(s,cursor)
  in chain(remaining-1,s,meta,node,p.parent) end
implement glyph_run_attachment_check(s,meta,node,p) = case+ p.attachment of
  | AttachmentNone() => if ieq(p.parent,~1) then AttachmentValid() else AttachmentInvalid()
  | AttachmentMark() => if ilt(p.parent,0) then AttachmentInvalid()
    else chain(airlock_nat(iadd(meta.used,1)),s,meta,node,p.parent)
  | AttachmentCursive() => if ilt(p.parent,0) then AttachmentInvalid()
    else chain(airlock_nat(iadd(meta.used,1)),s,meta,node,p.parent)
