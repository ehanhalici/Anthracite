# Incremental ATS -> C step. Each output depends only on the files that its own
# source really reads (staload/#include closure from `patsopt --depgen`), not on
# every interface in the tree. The depfile is rewritten on each run, so a new
# #include is picked up the next time the source is regenerated.
#
#   anthracite_ats_compile(<output.c> <source.dats>
#     [TYPECHECK] [INCLUDES dir...] [OPTIONS opt...] [DEPENDS file...] [COMMENT text])
function(anthracite_ats_compile OUTPUT SOURCE)
  cmake_parse_arguments(ARG "TYPECHECK" "COMMENT" "INCLUDES;OPTIONS;DEPENDS" ${ARGN})
  set(include_flags "")
  foreach(directory IN LISTS ARG_INCLUDES)
    list(APPEND include_flags -IATS "${directory}")
  endforeach()
  set(typecheck "")
  if(ARG_TYPECHECK)
    set(typecheck COMMAND patsopt -tc ${include_flags} -d "${SOURCE}")
  endif()
  list(JOIN include_flags " " depgen_flags)
  set(depfile "${OUTPUT}.d")
  if(NOT ARG_COMMENT)
    set(ARG_COMMENT "[ATS] ${SOURCE}")
  endif()
  add_custom_command(
    OUTPUT "${OUTPUT}"
    ${typecheck}
    COMMAND patsopt ${ARG_OPTIONS} ${include_flags} -o "${OUTPUT}" -d "${SOURCE}"
    COMMAND sh -c "patsopt --depgen ${depgen_flags} -d '${SOURCE}' | sed 's|^[^:]*:|${OUTPUT}:|' > '${depfile}'"
    DEPENDS "${SOURCE}" ${ARG_DEPENDS}
    DEPFILE "${depfile}"
    COMMENT "${ARG_COMMENT}"
    VERBATIM)
endfunction()
