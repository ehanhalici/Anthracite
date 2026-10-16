file(GLOB_RECURSE OT_CONTEXT_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_context_*.dats")
set(OT_CONTEXT_C_SOURCES "")
foreach(SOURCE ${OT_CONTEXT_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND OT_CONTEXT_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(OT_CONTEXT_TEST_C_SOURCES "")
foreach(MODULE ot_context_fixture ot_context_match_cases ot_context_priority_cases
    ot_context_error_cases ot_context_stress_cases ot_context_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/opentype/context/ot_context_contracts.sats tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND OT_CONTEXT_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(ot_context_conformance EXCLUDE_FROM_ALL ${OT_CONTEXT_C_SOURCES} ${OT_COV_CACHE_C_SOURCES}
  ${OT_CONTEXT_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(ot_context_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(ot_context_conformance m)
add_test(NAME ot_context_conformance COMMAND ot_context_conformance)
add_test(NAME ot_context_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_ot_context_type_error.cmake")
