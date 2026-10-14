set(SCRIPT_TOOL_C_SOURCES "")
foreach(MODULE script_compile script_source_range script_aliases_read script_aliases_query script_source_compile
    script_extensions_source script_extensions_write script_extensions_compile)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tools" -d "${CMAKE_SOURCE_DIR}/tools/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tools" -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tools/${MODULE}.dats"
    DEPENDS "tools/${MODULE}.dats" tools/script_compile.sats tools/script_compile_internal.hats ${ATS_INTERFACES})
  list(APPEND SCRIPT_TOOL_C_SOURCES "${OUTPUT}")
endforeach()
set(SCRIPT_C_SOURCES "")
foreach(MODULE script_code script_extensions_load script_extensions_validate script_extensions_query
    script_data_check script_data_load script_data_query)
  list(APPEND SCRIPT_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
add_executable(script_compile EXCLUDE_FROM_ALL ${SCRIPT_TOOL_C_SOURCES} ${SCRIPT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/property_writer_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c")
target_compile_definitions(script_compile PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(script_compile m)
set(SCRIPT_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/unicode18-script.bin")
set(SCRIPT_EXTENSIONS_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/unicode18-script-extensions.bin")
add_custom_command(OUTPUT "${SCRIPT_OUTPUT}" "${SCRIPT_EXTENSIONS_OUTPUT}"
  COMMAND script_compile "${UCD_SOURCE}/PropertyValueAliases.txt" "${UCD_SOURCE}/Scripts.txt"
    "${UCD_SOURCE}/ScriptExtensions.txt" "${SCRIPT_OUTPUT}" "${SCRIPT_EXTENSIONS_OUTPUT}"
  DEPENDS script_compile "${UCD_SOURCE}/PropertyValueAliases.txt" "${UCD_SOURCE}/Scripts.txt" "${UCD_SOURCE}/ScriptExtensions.txt")
add_custom_target(script_data DEPENDS "${SCRIPT_OUTPUT}" "${SCRIPT_EXTENSIONS_OUTPUT}")
