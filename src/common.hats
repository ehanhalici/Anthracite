#ifndef ANTHRACITE_COMMON_HATS
#define ANTHRACITE_COMMON_HATS

fun iadd(a: int, b: int): int = a + b
fun isub(a: int, b: int): int = a - b
fun imul(a: int, b: int): int = a * b
fun idiv(a: int, b: int): int = if b = 0 then 0 else a / b
fun imod(a: int, b: int): int = if b = 0 then 0 else a % b

fun imin(a: int, b: int): int = if a < b then a else b
fun imax(a: int, b: int): int = if a > b then a else b
fun iabs(a: int): int = if a < 0 then 0 - a else a

fun iif(c: bool, a: int, b: int): int = if c then a else b
fun ieq(a: int, b: int): bool = a = b
fun ine(a: int, b: int): bool = a <> b
fun ilt(a: int, b: int): bool = a < b
fun igt(a: int, b: int): bool = a > b
fun ile(a: int, b: int): bool = a <= b
fun ige(a: int, b: int): bool = a >= b

#endif
