staload "mem.sats"
staload "data_ast/document/doc.sats"
typedef AnchorTarget = @{found=bool,start=int,finish=int,marker=int}
(* Empty anchor selects the whole file. ^id selects an exact block ID;
   otherwise an exact heading title and its section are selected. *)
fun doc_resolve_anchor(d: !Doc,anchor: !Buf): AnchorTarget
(* Index storage belongs to Doc and is invalidated when AST nodes are cleared. *)
fun doc_anchor_index_take(d: !Doc): Buf
fun doc_anchor_index_put(d: !Doc,index: Buf): void
