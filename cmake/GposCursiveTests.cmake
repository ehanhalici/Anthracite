file(GLOB GPOS_CURSIVE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_cursive_*.dats")
set(GPOS_CURSIVE_C_SOURCES "")
foreach(SOURCE ${GPOS_CURSIVE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_CURSIVE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_CURSIVE_TEST_C_SOURCES "")
foreach(MODULE gpos_cursive_match_cases gpos_cursive_error_cases gpos_cursive_stress_cases gpos_cursive_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gpos_cursive_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GPOS_CURSIVE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gpos_cursive_conformance EXCLUDE_FROM_ALL ${GPOS_CURSIVE_C_SOURCES} ${GPOS_VALUE_C_SOURCES}
  ${GPOS_CURSIVE_TEST_C_SOURCES} ${OT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gpos_cursive_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gpos_cursive_conformance m)
add_test(NAME gpos_cursive_conformance COMMAND gpos_cursive_conformance)
add_test(NAME gpos_anchor_cache_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_gpos_anchor_cache_error.cmake")
