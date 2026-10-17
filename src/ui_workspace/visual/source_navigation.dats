#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/editing/doc_source_edit.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/commands/ui_cmd.sats"
staload "ui_workspace/visual/source_navigation.sats"
fun edit_of(cmd: Cmd): Option_vt(SourceEdit) =
  if is_cmd(cmd,CMD_CARET_LEFT) then Some_vt(SourceLeft())
  else if is_cmd(cmd,CMD_CARET_RIGHT) then Some_vt(SourceRight())
  else if is_cmd(cmd,CMD_SELECT_LEFT) then Some_vt(SourceSelectLeft())
  else if is_cmd(cmd,CMD_SELECT_RIGHT) then Some_vt(SourceSelectRight())
  else if is_cmd(cmd,CMD_BACKSPACE) then Some_vt(SourceBackspace())
  else if is_cmd(cmd,CMD_DELETE) then Some_vt(SourceDelete()) else None_vt()
fun command(f: !Font,d: !Doc,cmd: Cmd,scratch: &Buf >> _): Cmd = case+ edit_of(cmd) of
  | ~None_vt() => cmd | ~Some_vt(edit) => if doc_source_edit(f,d,edit,scratch) then CMD_NONE() else cmd
extern fun exhausted(ts: Tabs): Tabs = "mac#anth_die_box"
fun walk{n:nat} .<n>. (fuel: int(n),f: !Font,ts: Tabs,idx: int,cmd: Cmd,scratch: &Buf >> _): @(Tabs,Cmd) =
  if fuel = 0 then (exhausted(ts),cmd) else case+ ts of
    | ~TNil() => (TNil(),cmd)
    | ~TCons(d,path,title,scroll,rest) =>
      if ieq(idx,0) then let val result=command(f,d,cmd,scratch) in (TCons(d,path,title,scroll,rest),result) end
      else let val (tail,result)=walk(fuel-1,f,rest,isub(idx,1),cmd,scratch)
      in (TCons(d,path,title,scroll,tail),result) end
implement tabs_source_edit(f,ts,idx,cmd,scratch) = walk(airlock_nat(MAX_REC_FUEL),f,ts,idx,cmd,scratch)
