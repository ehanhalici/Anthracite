staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
datatype ArabicMarkRole = MarkModifierBelow | MarkModifierAbove | MarkShadda | MarkOther
datatype ArabicMarkPrefix = MarkPrefixOpen | MarkPrefixClosed
typedef ArabicMarkState = @{ccc=int,gate=ArabicMarkPrefix}
typedef ArabicMarkStep = @{state=ArabicMarkState,role=ArabicMarkRole}
typedef ArabicMarkUnit = @{scalar=int,start=int,finish=int}
datavtype ArabicMarkResult = ArabicMarksReady of ScalarText | ArabicMarksRejected of NormalizationError
