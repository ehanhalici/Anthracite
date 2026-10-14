staload "mem.sats"
(* Nullary Unicode roles: no per-scalar allocation. Codes exist only in
   binary property/storage adapters. LMissing is context, never a scalar. *)
datatype LineClass =
  | LXX | LAI | LAK | LAL | LAP | LAS
  | LB2 | LBA | LBB | LBK | LCB | LCJ
  | LCL | LCM | LCP | LCR | LEB | LEM
  | LEX | LH2 | LH3 | LHH | LHL | LHY
  | LID | LIN | LIS | LJL | LJT | LJV
  | LLF | LNL | LNS | LNU | LOP | LPO
  | LPR | LQU | LRI | LSA | LSG | LSP
  | LSY | LVF | LVI | LWJ | LZW | LZWJ

  | LGL | LMissing
datatype LineDecision = LinePending | LineForbidden | LineOptional | LineMandatory
datatype LineBreak = BreakForbidden | BreakOptional | BreakMandatory
typedef LineFacts = @{east=bool,initial=bool,final=bool,potential=bool}
typedef LineToken = @{kind=LineClass,cp=int,facts=LineFacts,zwj=bool,source=int}
typedef LineState = @{anchor=int,numeric=bool,beforeNumeric=bool,regional=int}
typedef LineContext = @{left=LineToken,right=LineToken,before=LineToken,
  next=LineToken,next2=LineToken,anchor=LineToken,beforeAnchor=LineToken,state=LineState}
datavtype LineTokens = LineTokens of (Buf,Buf,Buf,Buf,Buf,int)
datavtype LineBreakMap = LineBreakMap of (Buf,int)

fun line_class_of(code: int): LineClass
fun line_class_code(kind: LineClass): int
fun line_break_of(code: int): LineBreak
fun line_break_code(boundary: LineBreak): int
fun line_finalize(decision: LineDecision): LineBreak
