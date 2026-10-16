#ifndef ANTHRACITE_COMMON_HATS
#define ANTHRACITE_COMMON_HATS

#include "foundation/units.hats"

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
macdef CHAR_CR = 13
macdef CHAR_SPACE = 32
macdef CHAR_EXCL = 33
macdef CHAR_QUOTE = 34
macdef CHAR_HASH = 35
macdef CHAR_DOLLAR = 36
macdef CHAR_PERCENT = 37
macdef CHAR_AMPERSAND = 38
macdef CHAR_APOSTROPHE = 39
macdef CHAR_LPAREN = 40
macdef CHAR_RPAREN = 41
macdef CHAR_STAR = 42
macdef CHAR_PLUS = 43
macdef CHAR_COMMA = 44
macdef CHAR_MINUS = 45
macdef CHAR_DOT = 46
macdef CHAR_SLASH = 47
macdef CHAR_ZERO = 48
macdef CHAR_NINE = 57
macdef CHAR_COLON = 58
macdef CHAR_SEMICOLON = 59
macdef CHAR_LT = 60
macdef CHAR_EQUAL = 61
macdef CHAR_GT = 62
macdef CHAR_QUESTION = 63
macdef CHAR_AT = 64
macdef CHAR_UPPER_A = 65
macdef CHAR_UPPER_Z = 90
macdef CHAR_LBRACKET = 91
macdef CHAR_BACKSLASH = 92
macdef CHAR_RBRACKET = 93
macdef CHAR_CARET = 94
macdef CHAR_UNDERSCORE = 95
macdef CHAR_BACKTICK = 96
macdef CHAR_LOWER_A = 97
macdef CHAR_LOWER_Z = 122
macdef CHAR_LBRACE = 123
macdef CHAR_PIPE = 124
macdef CHAR_RBRACE = 125
macdef CHAR_TILDE = 126
macdef CHAR_ESC = 27
macdef CHAR_DEL = 127

#endif
