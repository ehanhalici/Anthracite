#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_font/glyph_nominal.sats"
staload "data_font/glyph_nominal_work.sats"
fun populate(b: !Buf,info: SfntInfo,db: !UnicodeDb,text: !ScalarText,run: GlyphRun(0),mask: uint,count: int): GlyphRunCreated = let
  val+ ~GlyphRun(phase,meta,s)=run
  val ()=glyph_nominal_fill_bytes(b,info,db,text,s,mask,count)
in GlyphRunCreated(GlyphRun(phase,glyph_nominal_meta(meta,count),s)) end
implement glyph_nominal_read(face,db,text,font,mask) = let val+ SfntFace(b,info)=face
in glyph_nominal_read_bytes(b,info,db,text,font,mask) end
implement glyph_nominal_read_bytes(b,info,db,text,font,mask) = let
  val count=scalar_count(text)
  val length=glyph_nominal_source_extent(text)
in case+ glyph_run_make(font,info.glyphs,length,count) of
  | ~GlyphRunRejected(status) => GlyphRunRejected(status)
  | ~GlyphRunCreated(run) => populate(b,info,db,text,run,mask,count) end
