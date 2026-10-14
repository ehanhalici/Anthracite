staload "mem.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_cmd.sats"
fun tabs_source_edit(f: !Font,ts: Tabs,idx: int,cmd: Cmd,scratch: &Buf >> _): @(Tabs,Cmd)
