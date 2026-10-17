staload "mem.sats"
staload "data_text/unicode/unicode_property.sats"
(* ISO 15924 four-byte identifiers are serialized data, not execution modes. *)
typedef ScriptCode = @{code=int}
datatype ScriptSetKind = ScriptSingleton | ScriptExplicitSet
typedef ScriptSet = @{kind=ScriptSetKind,script=ScriptCode,offset=int,count=int}
datavtype ScriptExtensions = ScriptExtensions of (Buf,int,int)
datavtype ScriptExtensionsRead = ScriptExtensionsAccepted of ScriptExtensions
  | ScriptExtensionsRejected of PropertyError
macdef SCRIPT_EXTENSIONS_MAGIC = 1095975768
macdef SCRIPT_COMMON = 1517910393
macdef SCRIPT_INHERITED = 1516858984
macdef SCRIPT_UNKNOWN = 1517976186
