#include "data_text/script_internal.hats"
staload "data_text/text_source.sats"
fun header(b: !Buf): bool = let
  val bytes=buf_len(b) val count=buf_get32(b,2) and total=buf_get32(b,3)
in ige(bytes,16) andalso ieq(imod(bytes,4),0) andalso ieq(buf_get32(b,0),SCRIPT_EXTENSIONS_MAGIC)
  andalso ieq(buf_get32(b,1),PROPERTY_VERSION) andalso ige(count,0) andalso ige(total,0)
  andalso ile(count,idiv(isub(bytes,16),16)) andalso ieq(total,isub(idiv(isub(bytes,16),4),imul(count,4))) end
fun rejected(b: Buf,error: PropertyError): ScriptExtensionsRead = let val ()=buf_free(b)
in ScriptExtensionsRejected(error) end
implement script_extensions_parse(b) =
  if not(header(b)) then rejected(b,PropertyHeader()) else let
    val count=buf_get32(b,2) and total=buf_get32(b,3)
  in if script_extensions_valid(b,count,total) then ScriptExtensionsAccepted(ScriptExtensions(b,count,total))
    else rejected(b,PropertyRanges()) end
implement script_extensions_load(path) = case+ text_file_read(path) of
  | ~TextFileError(code) => ScriptExtensionsRejected(PropertyIo(code))
  | ~TextFile(b) => script_extensions_parse(b)
implement script_extensions_dispose(extensions) = let val+ ~ScriptExtensions(b,count,total)=extensions
in buf_free(b) end
