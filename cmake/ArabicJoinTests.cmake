file(GLOB_RECURSE ARABIC_JOIN_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/src/data_text/arabic_join_*.dats" "${CMAKE_SOURCE_DIR}/src/data_font/glyph_arabic_*.dats")
set(ARABIC_JOIN_C_SOURCES "")
foreach(SOURCE ${ARABIC_JOIN_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND ARABIC_JOIN_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
target_sources(glyph_pass_conformance PRIVATE ${ARABIC_JOIN_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c")
add_dependencies(glyph_pass_conformance unicode_data unicode_properties)
set(ARABIC_JOIN_TEST_C_SOURCES "")
foreach(MODULE arabic_join_fixture arabic_join_checks arabic_join_examples arabic_join_mask_cases
    arabic_join_model arabic_join_rule_fixture arabic_join_rules arabic_join_stress arabic_join_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/text/arabic/joining/arabic_join_contracts.sats tests/font/glyph/run/glyph_run_contracts.sats
      tests/font/opentype/tables/opentype_fixture.sats tests/text/utf8/utf8_contracts.sats ${ATS_INTERFACES})
  list(APPEND ARABIC_JOIN_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(arabic_join_conformance EXCLUDE_FROM_ALL ${ARABIC_JOIN_C_SOURCES} ${ARABIC_JOIN_TEST_C_SOURCES}
  ${GLYPH_RUN_C_SOURCES} ${UTF8_C_SOURCES} ${OT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_run_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/utf8_encoding_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c")
target_compile_definitions(arabic_join_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(arabic_join_conformance m)
add_dependencies(arabic_join_conformance unicode_properties)
add_test(NAME arabic_join_conformance COMMAND arabic_join_conformance "${CMAKE_CURRENT_BINARY_DIR}/unicode18-joining.bin")
add_test(NAME arabic_join_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_arabic_join_error.cmake")
