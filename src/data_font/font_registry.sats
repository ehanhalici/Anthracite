(* Automatic face-registry allocation. IDs are strictly increasing positive
   integers and never repeat, so live faces cannot collide and disposed faces
   cannot cause ABA reuse. Exhaustion is a deterministic typed abort. *)
%{#
#include "data_font/font_registry.cats"
%}

staload "data_font/font.sats"
fun font_registry_next(): int
fun font_registry_id(f: !Font): int
fun font_registry_load(): int = "ext#anth_font_registry_load"
fun font_registry_store(v: int): void = "ext#anth_font_registry_store"
