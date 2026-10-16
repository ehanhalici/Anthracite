#define ATS_DYNLOADFLAG 0

staload "mem.sats"
#include "foundation/units.hats"

macdef IX_FILE_STRIDE = 8
macdef IX_FILE_BYTES = IX_FILE_STRIDE * WORD32_BYTES
macdef IX_F_PATHOFF = 0
macdef IX_F_PATHLEN = 1
macdef IX_F_SIZE = 2
macdef IX_F_MTIME = 3
macdef IX_F_STATE = 4
macdef IX_F_DOCVER = 5
macdef IX_F_SYMFIRST = 6
macdef IX_F_SYMCOUNT = 7

macdef IX_SYM_STRIDE = 8
macdef IX_SYM_BYTES = IX_SYM_STRIDE * WORD32_BYTES
macdef IX_S_FILE = 0
macdef IX_S_KIND = 1
macdef IX_S_START = 2
macdef IX_S_END = 3
macdef IX_S_LINE = 4
macdef IX_S_TEXTOFF = 5
macdef IX_S_TEXTLEN = 6
macdef IX_S_AUX = 7

macdef BLOOM_BYTES_PER_FILE = 256
macdef BLOOM_BITS_PER_FILE = BLOOM_BYTES_PER_FILE * BYTE_BITS

macdef MAX_INDEX_FILES = 20000
macdef MAX_INDEX_DEPTH = 12
macdef MAX_HITS_PER_FILE = 8
macdef MAX_SEARCH_HITS = 200

macdef IX_JUMP_STRIDE = 3
macdef IX_J_FILE = 0
macdef IX_J_LINE = 1
macdef IX_J_COL = 2

fun ix_file_count(ixf: !Buf): int
fun ix_file_get(ixf: !Buf, fid: int, field: int): int
fun ix_file_set(ixf: !Buf, fid: int, field: int, v: int): void
fun ix_file_add(ixf: &Buf >> _, poff: int, plen: int, sz: int, mt: int, st: int, dver: int, sfirst: int, scnt: int): int

fun ix_sym_count(ixs: !Buf): int
fun ix_sym_get(ixs: !Buf, sid: int, field: int): int
fun ix_sym_set(ixs: !Buf, sid: int, field: int, v: int): void
fun ix_sym_add(ixs: &Buf >> _, fid: int, kind: int, st: int, en: int, line: int, toff: int, tlen: int, aux: int): int

fun ix_bloom_ensure(ixb: &Buf >> _, nfiles: int): void
fun ix_bloom_set_trigram(ixb: !Buf, fid: int, b0: int, b1: int, b2: int): void
fun ix_bloom_test_trigram(ixb: !Buf, fid: int, b0: int, b1: int, b2: int): bool
