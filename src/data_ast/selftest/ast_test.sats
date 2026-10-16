#define ATS_DYNLOADFLAG 0

fun ast_expect(src: string, want: string): bool
fun ast_fuzz(seed: int, steps: int): bool
fun ast_selftest(): int
