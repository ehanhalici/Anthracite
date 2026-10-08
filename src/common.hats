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

fun ieq(a: int, b: int): bool = a = b
fun ine(a: int, b: int): bool = a <> b
fun ilt(a: int, b: int): bool = a < b
fun igt(a: int, b: int): bool = a > b
fun ile(a: int, b: int): bool = a <= b
fun ige(a: int, b: int): bool = a >= b
 
macdef CHAR_TAB = 9
macdef CHAR_LF = 10
macdef CHAR_SPACE = 32
macdef CHAR_EXCL = 33
macdef CHAR_QUOTE = 34
macdef CHAR_HASH = 35
macdef CHAR_DOLLAR = 36
macdef CHAR_LPAREN = 40
macdef CHAR_RPAREN = 41
macdef CHAR_STAR = 42
macdef CHAR_PLUS = 43
macdef CHAR_MINUS = 45
macdef CHAR_DOT = 46
macdef CHAR_SLASH = 47
macdef CHAR_ZERO = 48
macdef CHAR_NINE = 57
macdef CHAR_COLON = 58
macdef CHAR_EQUAL = 61
macdef CHAR_GT = 62
macdef CHAR_LBRACKET = 91
macdef CHAR_RBRACKET = 93
macdef CHAR_CARET = 94
macdef CHAR_UNDERSCORE = 95
macdef CHAR_PIPE = 124
macdef CHAR_TILDE = 126
macdef CHAR_ESC = 27
macdef CHAR_DEL = 127

macdef KEY_CHAR_A = 97
macdef KEY_CHAR_B = 98
macdef KEY_CHAR_C = 99
macdef KEY_CHAR_E = 101
macdef KEY_CHAR_F = 102
macdef KEY_CHAR_I = 105
macdef KEY_CHAR_K = 107
macdef KEY_CHAR_N = 110
macdef KEY_CHAR_O = 111
macdef KEY_CHAR_P = 112
macdef KEY_CHAR_S_UPPER = 83
macdef KEY_CHAR_S = 115
macdef KEY_CHAR_T = 116
macdef KEY_CHAR_V = 118
macdef KEY_CHAR_W = 119
macdef KEY_CHAR_X = 120
macdef KEY_CHAR_Y = 121
macdef KEY_CHAR_Z = 122

#endif
