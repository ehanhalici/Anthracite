staload "mem.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/glyph_context_arena_types.sats"
staload "data_font/glyph_substitution_stack_types.sats"
datavtype GlyphSubstitutionWorkspace = GlyphSubstitutionWorkspace of
  (GlyphContextWindow,GlyphSubstitutionStack,GlyphContextArena,Buf,Buf,Buf,Buf,int)
datavtype GlyphSubstitutionWorkspaceRead = SubWorkspaceAccepted of GlyphSubstitutionWorkspace
  | SubWorkspaceRejected of GlyphPassStatus
datatype GlyphSubstitutionEventKind = SubContinue | SubReturned | SubFault
typedef GlyphSubstitutionEvent = @{kind=GlyphSubstitutionEventKind,depth=int,status=GlyphPassStatus,next=int,matched=bool}
datatype GlyphSubstitutionTraversal = SubForward | SubReverse
typedef GlyphSubstitutionCounts = @{status=GlyphPassStatus,visited=int,matches=int}
typedef GlyphSubstitutionCapacity = @{status=GlyphPassStatus,rows=int,frames=int,slots=int}
