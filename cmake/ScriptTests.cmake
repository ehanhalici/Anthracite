set(SCRIPT_TEST_C_SOURCES "")
foreach(MODULE script_units script_rejections script_source_oracle script_extensions_oracle script_ignorable_oracle script_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tools"
      -IATS "${CMAKE_SOURCE_DIR}/tests" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tools"
      -IATS "${CMAKE_SOURCE_DIR}/tests" -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/script_contracts.sats tests/script_test.hats
      tools/script_compile.sats tools/script_compile_internal.hats ${ATS_INTERFACES})
  list(APPEND SCRIPT_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(script_conformance EXCLUDE_FROM_ALL ${SCRIPT_TEST_C_SOURCES} ${SCRIPT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/script_source_range_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/script_aliases_read_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/script_aliases_query_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c")
target_compile_definitions(script_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(script_conformance m)
add_dependencies(script_conformance script_data unicode_properties)
add_test(NAME script_conformance COMMAND script_conformance "${SCRIPT_OUTPUT}" "${SCRIPT_EXTENSIONS_OUTPUT}"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-ignorable.bin" "${UCD_SOURCE}/PropertyValueAliases.txt"
  "${UCD_SOURCE}/Scripts.txt" "${UCD_SOURCE}/ScriptExtensions.txt" "${UCD_SOURCE}/DerivedCoreProperties.txt")
