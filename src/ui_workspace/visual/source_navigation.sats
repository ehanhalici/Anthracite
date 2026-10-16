staload "mem.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/commands/ui_cmd.sats"
fun tabs_source_edit(f: !Font,ts: Tabs,idx: int,cmd: Cmd,scratch: &Buf >> _): @(Tabs,Cmd)
