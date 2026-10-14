staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
(* FeatureParams payloads: 'size', stylistic sets (ssXX), and character
   variants (cv01..cv99). Unknown tags and absent children stay explicit. *)
datatype OtFeatureParams = ParamsSize of @{design=int,subfamily=int,name=int,record=int}
  | ParamsStylistic of @{version=int,name=int}
  | ParamsVariant of @{format=int,label=int,tooltip=int,sample=int,named=int,first=int}
  | ParamsAbsent
datavtype OtFeatureParamsRead = FeatureParamsAccepted of OtFeatureParams
  | FeatureParamsRejected of OtError
fun ot_feature_params_parse(b: !Buf,tag: OtTag,params: OtChild): OtFeatureParamsRead
