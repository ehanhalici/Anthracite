#define ATS_DYNLOADFLAG 0

staload "mem.sats"

datatype QOp =
  | QPlain of ()
  | QTag of ()
  | QWiki of ()
  | QHeading of ()
  | QFile of ()
  | QTask of ()
  | QCode of ()

fun qop_code(qop: QOp): int
fun qop_of(code: int): QOp

macdef MAX_QUERY_TERMS = 8

fun ix_query_parse(q: !Buf, pool: &Buf >> _, terms: &Buf >> _): int
