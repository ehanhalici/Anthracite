file(GLOB GPOS_MARK_MATRIX_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_mark_matrix_*.dats")
file(GLOB GPOS_MARK_SHARED_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_mark_shared_*.dats")
set(GPOS_MARK_SHARED_C_SOURCES "")
foreach(SOURCE ${GPOS_MARK_SHARED_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_MARK_SHARED_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_MARK_MATRIX_C_SOURCES "")
foreach(SOURCE ${GPOS_MARK_MATRIX_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_MARK_MATRIX_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_MARK_MATRIX_TEST_C_SOURCES "")
foreach(MODULE gpos_mark_matrix_match_cases gpos_mark_matrix_error_cases gpos_mark_matrix_stress_cases
    gpos_mark_matrix_font_cases gpos_mark_matrix_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gpos_mark_matrix_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GPOS_MARK_MATRIX_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gpos_mark_matrix_conformance EXCLUDE_FROM_ALL ${GPOS_MARK_MATRIX_C_SOURCES} ${GPOS_VALUE_C_SOURCES} ${GPOS_MARK_SHARED_C_SOURCES}
  ${GPOS_MARK_MATRIX_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gpos_mark_matrix_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gpos_mark_matrix_conformance m)
add_test(NAME gpos_mark_matrix_conformance COMMAND gpos_mark_matrix_conformance)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME gpos_mark_matrix_font_conformance COMMAND gpos_mark_matrix_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
