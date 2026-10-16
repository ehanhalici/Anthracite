#include "script_compile_internal.hats"
implement script_extensions_compile(aliases,path,output) = case+ text_file_read(path) of
  | ~TextFileError(code) => false | ~TextFile(b) => let
    var rows: Buf=buf_make(1024) and tags: Buf=buf_make(1024)
    val result=script_extensions_source(aliases,b,rows,tags)
    val written=result.valid andalso script_extensions_write(rows,tags,result.rows,result.total,output)
    val ()=buf_free(b) and ()=buf_free(rows) and ()=buf_free(tags)
  in written end
