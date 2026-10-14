file(GLOB SCRIPT_ITEMS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_text/script_items_*.dats")
set(SCRIPT_ITEMS_C_SOURCES "")
foreach(SOURCE ${SCRIPT_ITEMS_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND SCRIPT_ITEMS_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(SCRIPT_ITEMS_TEST_C_SOURCES "")
foreach(MODULE script_items_cases script_items_stress script_items_rejections script_items_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tools"
      -IATS "${CMAKE_SOURCE_DIR}/tests" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tools"
      -IATS "${CMAKE_SOURCE_DIR}/tests" -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/script_items_contracts.sats tests/script_items_test.hats tests/script_test.hats
      tests/script_contracts.sats tools/script_compile.sats tools/script_compile_internal.hats ${ATS_INTERFACES})
  list(APPEND SCRIPT_ITEMS_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(script_items_conformance EXCLUDE_FROM_ALL ${SCRIPT_ITEMS_TEST_C_SOURCES} ${SCRIPT_ITEMS_C_SOURCES}
  ${SCRIPT_C_SOURCES} ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/grapheme_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/script_source_range_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_bracket_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_bracket_lookup_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_class_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_predicates_dats.c")
target_compile_definitions(script_items_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(script_items_conformance m)
add_dependencies(script_items_conformance script_data unicode_data unicode_properties)
add_test(NAME script_items_conformance COMMAND script_items_conformance "${SCRIPT_OUTPUT}" "${SCRIPT_EXTENSIONS_OUTPUT}"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-bidi.bin"
  "${UCD_SOURCE}/BidiBrackets.txt")
