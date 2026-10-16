implement font_text_take(f) = case+ f of | @FONT(s) => let
  val state=s.text_session val ()=s.text_session := None_vt() prval ()=fold@(f)
in state end
implement font_text_put(f,state) = case+ f of | @FONT(s) => let
  val old=s.text_session val ()=s.text_session := state prval ()=fold@(f)
in font_text_session_release(old) end
implement font_text_active(f) = case+ f of | @FONT(s) => let
  val active=case+ s.text_session of
    | @None_vt() => let prval ()=fold@(s.text_session) in false end
    | @Some_vt(session) => let prval ()=fold@(s.text_session) in true end
  prval ()=fold@(f)
in active end
