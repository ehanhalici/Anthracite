staload "mem.sats"
datavtype BidiMirrors = BidiMirrors of (Buf, int)
datatype MirrorError = MirrorIo of int | MirrorData
datavtype MirrorLoad = MirrorsLoaded of BidiMirrors | MirrorsRejected of MirrorError
fun bidi_mirrors_load(path: string): MirrorLoad
fun bidi_mirrors_parse(source: !Buf): MirrorLoad
fun bidi_mirror_codepoint(data: !BidiMirrors, cp: int, level: int): int
fun bidi_mirrors_dispose(data: BidiMirrors): void

