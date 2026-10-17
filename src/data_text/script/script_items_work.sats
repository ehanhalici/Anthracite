staload "data_text/script/script_items.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/script/script_types.sats"
staload "data_text/script/script_data_types.sats"
staload "data_text/script/script_items_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
fun script_items_charge(remaining: &int >> int,cost: int): bool
fun script_items_wild(set: ScriptSet): bool
fun script_items_initial(start: int): ScriptItemsState
fun script_items_cluster(data: !ScriptData,text: !ScalarText,w: !ScriptItemsWorkspace,start: int): ScriptCluster
fun script_items_choice(w: !ScriptItemsWorkspace,count: int,preferred: ScriptCode): ScriptCode
fun script_items_candidate(data: !ScriptData,w: !ScriptItemsWorkspace,set: ScriptSet,
  state: ScriptItemsState,remaining: &int >> int): ScriptCandidate
fun script_items_fill(w: !ScriptItemsWorkspace,start: int,finish: int,code: ScriptCode): void
fun script_items_pair(brackets: !BidiBrackets,w: !ScriptItemsWorkspace,cp: int,index: int,depth: int): ScriptPair
fun script_items_pair_set(w: !ScriptItemsWorkspace,cluster: ScriptCluster,pair: ScriptPair,start: int): ScriptSet
fun script_items_pair_reset(w: !ScriptItemsWorkspace): void
fun script_items_walk(data: !ScriptData,bidi: !PropertyMap(2),text: !ScalarText,brackets: !BidiBrackets,
  w: !ScriptItemsWorkspace,remaining: &int >> int): ScriptItemsStatus
