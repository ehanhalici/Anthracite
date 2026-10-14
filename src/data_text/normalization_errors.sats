staload "mem.sats"
staload "data_text/normalization_types.sats"
fun NormIo(code: int): NormalizationError
fun NormHeader(): NormalizationError
fun NormRanges(): NormalizationError
fun NormGraph(): NormalizationError
fun NormSource(): NormalizationError
fun NormLength(): NormalizationError
