staload "mem.sats"
staload "data_text/unicode_property.sats"
fun property_write{kind:int}(domain: PropertyDomain(kind), dense: !Buf, path: string): bool
