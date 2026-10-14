#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_work.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_text/grapheme.sats"
staload "data_font/glyph_nominal_work.sats"
fun fill{n,k:nat} .<k>. (left: int(k),b: !Buf,info: SfntInfo,db: !UnicodeDb,text: !ScalarText,s: !GlyphStorage(n),
  mask: uint,state: GraphemeState,cluster: int,index: int): void = if left = 0 then () else let
    val cp=scalar_value(text,index) and start=scalar_start(text,index)
    val step=grapheme_step(db,state,cp)
    val current=if step.boundary then start else cluster
    val seed: GlyphSeed= @{glyph=sfnt_map(b,info,cp),scalar=cp,sourceStart=start,
      sourceEnd=scalar_end(text,index),cluster=current,mask=mask}
    val next=if left = 1 then ~1 else iadd(index,1)
    val ()=glyph_run_initial(s,index,glyph_run_seed_core(seed),isub(index,1),next)
  in fill(left-1,b,info,db,text,s,mask,step.state,current,iadd(index,1)) end
implement glyph_nominal_fill(face,db,text,s,mask,count) = let val+ SfntFace(b,info)=face
in glyph_nominal_fill_bytes(b,info,db,text,s,mask,count) end
implement glyph_nominal_fill_bytes(b,info,db,text,s,mask,count) =
  fill(airlock_nat(count),b,info,db,text,s,mask,grapheme_initial(),0,0)
