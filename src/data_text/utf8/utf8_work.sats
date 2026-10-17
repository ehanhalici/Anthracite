staload "mem.sats"
staload "data_text/utf8/utf8.sats"
typedef Utf8Unit = @{cp=int,next=int,errors=int}
typedef Utf8Measure = @{count=int,errors=int}
fun utf8_unit(step: Utf8Step,offset: int): Utf8Unit
fun utf8_measure(source: !Buf,length: int): Utf8Measure
fun utf8_store(source: !Buf,length: int,values: !Buf,starts: !Buf,ends: !Buf,count: int): void
