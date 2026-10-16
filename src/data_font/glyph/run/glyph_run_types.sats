(* Stable numeric node IDs and source byte spans. Dead nodes never relocate
   their neighbours; the three native columns hold flat, allocation-free rows. *)
staload "data_font/opentype/definition/gdef_types.sats"
datatype GlyphSourceProperties = GlyphSourceRaw | GlyphSourceUnicode
datatype GlyphRunPhase(int) = RunNominal(0) | RunSubstitution(1) | RunPositioning(2) | RunFrozen(3)
datatype GlyphLife = GlyphVacant | GlyphLive | GlyphRemoved
datatype GlyphAssociation = Unassociated | LigatureOwner | LigatureMark | LigatureForward
datatype GlyphAttachment = AttachmentNone | AttachmentMark | AttachmentCursive
typedef GlyphCore = @{glyph=int,scalar=int,sourceStart=int,sourceEnd=int,cluster=int,
  mask=uint,association=GlyphAssociation,ligature=int,component=int,components=int,multiplied=bool,
  unicodeKind=GdefGlyphKind,ignorable=bool}
typedef GlyphLinks = @{life=GlyphLife,previous=int,next=int}
typedef GlyphPosition = @{xAdvance=int,yAdvance=int,xOffset=int,yOffset=int,
  attachment=GlyphAttachment,parent=int,anchorX=int,anchorY=int}
typedef GlyphRunMeta = @{used=int,live=int,head=int,tail=int,font=int,glyphs=int,sourceLength=int,nextLigature=int,
  properties=GlyphSourceProperties}
datavtype GlyphStorage(int) = {n:nat}{a,b,c:addr} GlyphStorage(n) of
  (int(n),arrayptr(GlyphCore,a,n),arrayptr(GlyphLinks,b,n),arrayptr(GlyphPosition,c,n))
datavtype GlyphRun(phase:int) = {n:nat} GlyphRun(phase) of (GlyphRunPhase(phase),GlyphRunMeta,GlyphStorage(n))
datatype GlyphEditStatus = GlyphUpdated | GlyphUnchanged | GlyphCapacity | GlyphNode
  | GlyphDomain | GlyphSource | GlyphOrder | GlyphAssociationError | GlyphOverflow
datavtype GlyphRunCreated = GlyphRunCreated of GlyphRun(0) | GlyphRunRejected of GlyphEditStatus
datavtype GlyphRunEdit(phase:int) = GlyphRunEdited(phase) of (GlyphRun(phase),GlyphEditStatus,int)
datatype GlyphViewKind = GlyphMissing | GlyphPresent
typedef GlyphView = @{kind=GlyphViewKind,core=GlyphCore,links=GlyphLinks,position=GlyphPosition}
typedef GlyphSeed = @{glyph=int,scalar=int,sourceStart=int,sourceEnd=int,cluster=int,mask=uint}
typedef GlyphAssociationView = @{found=bool,owner=int,component=int,components=int}
datatype GlyphAttachmentCheck = AttachmentValid | AttachmentInvalid | AttachmentCycle
