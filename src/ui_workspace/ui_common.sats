staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun touchb(b: &Buf >> Buf): void
fun bclear(b: &Buf >> Buf): void
fun bpush(b: &Buf >> Buf, v: int): void
fun push_if(b: &Buf >> Buf, go: int, v: int): void
fun bappend(b: &Buf >> Buf, s: string, i: int, n: int): void
fun bstr(b: &Buf >> Buf, s: string): void
fun bstr_if(b: &Buf >> Buf, go: int, s: string): void
fun bcat(dst: &Buf >> Buf, src: !Buf, i: int, n: int): void
fun bcat_if(dst: &Buf >> Buf, src: !Buf, i: int, n: int, go: int): void
fun beq(a: !Buf, b: !Buf, i: int): int
fun bcopy(src: !Buf): Buf
fun cstr(b: !Buf): string
fun ends(b: !Buf, s: string): int
fun draw_s(f: !Font, r: !Rend, x: int, y: int, s: string, c: uint): int
fun join2(a: !Buf, b: !Buf): Buf
fun last_slash(path: !Buf, i: int, a: int): int
fun base_name(path: !Buf, dst: &Buf >> Buf): void
fun dirname_of(path: !Buf, dst: &Buf >> Buf): void
fun child_path(dir: !Buf, name: !Buf, dst: &Buf >> Buf): void
fun row_path(text: !Buf, meta: !Buf, row: int, dst: &Buf >> Buf): void
fun has_dot_char(b: !Buf, i: int): int
fun uok(t: uint): int
