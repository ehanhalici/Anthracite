staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
(* Interpreted FeatureParams (OpenType 1.9.1): 'size' (five uint16 values),
   stylistic sets ss01-ss20 (minor version and UI label) and character
   variants cv01-cv99 (format 0). Absent tables stay ParamsAbsent; registered
   tags with malformed data are rejected; other tags are ParamsOpaque. *)
datatype OtFeatureParams =
  | ParamsSize of @{design=int,subfamily=int,name=int,rangeStart=int,rangeEnd=int}
  | ParamsStylistic of @{version=int,name=int}
  | ParamsVariant of @{label=int,tooltip=int,sample=int,named=int,first=int,charCount=int}
  | ParamsOpaque
  | ParamsAbsent
datavtype OtFeatureParamsRead = FeatureParamsAccepted of OtFeatureParams
  | FeatureParamsRejected of OtError
fun ot_feature_params_parse(b: !Buf,tag: OtTag,params: OtChild): OtFeatureParamsRead
