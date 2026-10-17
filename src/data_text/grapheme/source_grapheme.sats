staload "mem.sats"
staload "data_text/unicode/unicode_db.sats"
typedef SourceBoundaries = @{previous=int,lower=int,upper=int,next=int}
fun source_grapheme_query(db: !UnicodeDb,source: !Buf,length: int,offset: int): SourceBoundaries
