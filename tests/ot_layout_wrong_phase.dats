#include "share/atspre_staload.hats"
staload "data_font/ot_layout_types.sats"
extern fun execute_lookup(table: !OtLayoutTable(1,1)): void
fun cannot_execute(table: !OtLayoutTable(1,0)): void = execute_lookup(table)

