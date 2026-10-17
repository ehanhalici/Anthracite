#include "data_font/native/text/native_text_analysis_internal.hats"
implement native_text_analysis_count(a) = let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a in scalar_count(text) end
implement native_text_analysis_level(a,index) = let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
in bidi_document_level(bidi,index) end
implement native_text_analysis_script(a,index) = let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
in script_items_code(scripts,index) end
implement native_text_analysis_grapheme(a,index) = let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
in ine(buf_get(graphemes,index),0) end
implement native_text_analysis_break(a,index) = let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
in line_break_at(breaks,index) end
implement native_text_analysis_dispose(a) = let val+ ~NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
  val ()=scalar_dispose(text) and ()=bidi_document_dispose(bidi) and ()=script_items_dispose(scripts)
  val ()=line_breaks_dispose(breaks)
in buf_free(graphemes) end
