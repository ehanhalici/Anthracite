#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "airlock.sats"
staload "data_font/font.sats"
staload "core_runtime/text_engine_startup.sats"
extern fun font_failed(): void = "mac#anth_die_void"
implement workspace_arabic_font_start(f) = let val path=workspace_arabic_font_path()
in if font_use_fallback_file(f,path) then
  println!("event=text_font role=arabic_fallback status=ready path=",path)
  else let val ()=println!("event=text_font role=arabic_fallback status=failed path=",path)
  in font_failed() end end
