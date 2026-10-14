#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "airlock.sats"
staload "data_font/font.sats"
staload "data_font/font_text.sats"
staload "data_font/font_text_types.sats"
staload "data_font/native_text_assets_types.sats"
staload "core_runtime/text_engine_startup.sats"
extern fun startup_failed(): void = "mac#anth_die_void"
fun activated(result: FontTextEnable): void = case+ result of
  | FontTextEnabled() =>
    println!("event=text_engine engine=native unicode=18.0.0 layout=shared_span document_rows=projected_pixel wrap=shared_body height=shared_body caret=shared_body status=ready")
  | FontTextAlreadyEnabled() => println!("event=text_engine engine=native status=already_ready")
  | FontTextAssetsFailed(error) => let
    val ()=println!("event=text_engine engine=native status=failed reason=unicode_assets detail=",error.detail)
  in startup_failed() end
implement workspace_font_start(f) =
  if not(font_load_default(f)) then let
    val ()=println!("event=text_engine engine=bitmap status=unavailable reason=primary_font")
  in false end else let
    val ()=workspace_arabic_font_start(f)
    (* The workspace owns one live Font. These IDs are scoped to that owner;
       automatic global registry allocation remains a separate migration. *)
    val ()=activated(font_text_enable(f,workspace_text_location(),1,2))
  in font_text_active(f) end
