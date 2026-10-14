staload "mem.sats"
staload "data_text/unicode_property.sats"
fun property_source_read{kind:int}(domain: PropertyDomain(kind), path: string, dense: !Buf): bool
