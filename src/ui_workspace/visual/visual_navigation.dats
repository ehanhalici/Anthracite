#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/doc_visual.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/font_text.sats"
staload "data_font/resources/font_document_metrics.sats"
staload "core_render/render.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/visual/visual_layout.sats"
staload "ui_workspace/visual/visual_query.sats"
staload "ui_workspace/visual/visual_navigation.sats"
datatype VerticalEdit = MoveUp | MoveDown | SelectUp | SelectDown
fun vertical_of(cmd: Cmd): Option(VerticalEdit) =
  if is_cmd(cmd,CMD_CARET_UP) then Some(MoveUp()) else if is_cmd(cmd,CMD_CARET_DOWN) then Some(MoveDown())
  else if is_cmd(cmd,CMD_SELECT_UP) then Some(SelectUp()) else if is_cmd(cmd,CMD_SELECT_DOWN) then Some(SelectDown()) else None()
fun snapshot{b:bool}(state: !option_vt(VisualRows,b)): Option(VisualKey) = case+ state of
  | None_vt() => None() | Some_vt(rows) => let val+ VisualRows(t,m,l,data,n,key,plans)=rows in Some(key) end
fun refresh(f: !Font,r: !Rend,d: !Doc): bool = let val state=doc_visual_take(d)
  val key=snapshot(state) val ()=doc_visual_put(d,state)
in case+ key of | None() => false | Some(k) => let
  val mode=case+ k.projection of | VisualSource() => ViewEdit() | VisualRendered() => ViewRead()
  val lh=font_document_line_height(f,font_line_h(f)) val ()=visual_layout_prepare(f,r,d,k.width,mode)
  val height=doc_layout_mode(d,lh,if is_view_read(mode) then 1 else 0,iadd(k.width,80))
in true end end
fun move(f: !Font,d: !Doc,m: VerticalEdit,scratch: &Buf >> _): void = let
  val lh=font_document_line_height(f,font_line_h(f)) val p=visual_caret_point(f,d,0,0,0,lh,scratch)
  val y=case+ m of | MoveUp() => isub(p.y,lh) | SelectUp() => isub(p.y,lh)
    | MoveDown() => iadd(p.y,lh) | SelectDown() => iadd(p.y,lh)
  val target=visual_click_source(f,d,p.x,y,0,0,0,lh,scratch)
in case+ m of | MoveUp() => doc_set_caret_move(d,target) | MoveDown() => doc_set_caret_move(d,target)
  | SelectUp() => doc_set_caret_extend(d,target) | SelectDown() => doc_set_caret_extend(d,target) end
fun command(f: !Font,r: !Rend,d: !Doc,cmd: Cmd,scratch: &Buf >> _): Cmd =
  if not(font_text_active(f)) then cmd else case+ vertical_of(cmd) of
    | None() => cmd | Some(m) => if not(refresh(f,r,d)) then cmd else let val ()=move(f,d,m,scratch) in CMD_NONE() end
extern fun exhausted(ts: Tabs): Tabs = "mac#anth_die_box"
fun walk{n:nat} .<n>. (fuel: int(n),f: !Font,r: !Rend,ts: Tabs,idx: int,cmd: Cmd,scratch: &Buf >> _): @(Tabs,Cmd) =
  if fuel = 0 then (exhausted(ts),cmd) else case+ ts of
    | ~TNil() => (TNil(),cmd)
    | ~TCons(d,path,title,scroll,rest) =>
      if ieq(idx,0) then let val result=command(f,r,d,cmd,scratch) in (TCons(d,path,title,scroll,rest),result) end
      else let val (tail,result)=walk(fuel-1,f,r,rest,isub(idx,1),cmd,scratch)
      in (TCons(d,path,title,scroll,tail),result) end
implement tabs_visual_vertical(f,r,ts,idx,cmd,scratch) = walk(airlock_nat(MAX_REC_FUEL),f,r,ts,idx,cmd,scratch)
