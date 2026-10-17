staload "mem.sats"
staload "data_text/utf8/utf8.sats"
datavtype LineFixture = LineFixture of (ScalarText,Buf)
fun line_fixture_parse(source: !Buf,start: int,endpos: int): LineFixture
