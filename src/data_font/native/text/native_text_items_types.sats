staload "mem.sats"
staload "data_text/script/script_types.sats"
(* Logical shaping partitions. These scalar ranges borrow the analysis view;
   they are not visual glyph order, font selections or pixel line boxes. *)
typedef NativeTextItem = @{start=int,finish=int,sourceStart=int,sourceEnd=int,
  level=int,script=ScriptCode}
datavtype NativeTextItems = {n:nat} NativeTextItems of (arrayptr(NativeTextItem,n),int(n))
datatype NativeItemsFailure = ItemsCapacity
datavtype NativeItemsRead = NativeItemsAccepted of NativeTextItems
  | NativeItemsRejected of NativeItemsFailure
