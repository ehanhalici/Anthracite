staload "mem.sats"

datatype PropertyDomain(int) =
  | WordProperty(1) | BidiProperty(2) | JoiningProperty(3)
  | LineProperty(4) | EastAsianProperty(5) | CategoryProperty(6)
  | ScriptProperty(7) | IgnorableProperty(8) | ModifierMarkProperty(9)
typedef AnyPropertyDomain = [kind:int] PropertyDomain(kind)
datatype PropertyError = PropertyIo of int | PropertyHeader | PropertyRanges
datavtype PropertyMap(int) = {kind:int} PropertyMap(kind) of (Buf, int)
datavtype PropertyLoad(int) =
  | {kind:int} PropertyLoaded(kind) of PropertyMap(kind)
  | {kind:int} PropertyRejected(kind) of PropertyError

macdef PROPERTY_MAGIC = 1096110160
macdef PROPERTY_VERSION = 180000
macdef UNICODE_SCALAR_LIMIT = 1114112

fun property_domain_code{kind:int}(domain: PropertyDomain(kind)): int
fun property_domain_max{kind:int}(domain: PropertyDomain(kind)): int
fun property_serialized_value_valid{kind:int}(domain: PropertyDomain(kind),value: int): bool
fun property_load{kind:int}(path: string, domain: PropertyDomain(kind)): PropertyLoad(kind)
fun property_parse{kind:int}(bytes: Buf, domain: PropertyDomain(kind)): PropertyLoad(kind)
fun property_value{kind:int}(map: !PropertyMap(kind), cp: int): int
fun property_dispose{kind:int}(map: PropertyMap(kind)): void
