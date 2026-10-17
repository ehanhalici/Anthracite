staload "mem.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "ui_workspace/tabs/ui_tab.sats"
staload "ui_workspace/commands/ui_cmd.sats"
fun tabs_visual_vertical(f: !Font,r: !Rend,ts: Tabs,idx: int,cmd: Cmd,scratch: &Buf >> _): @(Tabs,Cmd)
