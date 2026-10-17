file(GLOB_RECURSE GPOS_MARK_LIGATURE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_mark_ligature_*.dats")
set(GPOS_MARK_LIGATURE_C_SOURCES "")
foreach(SOURCE ${GPOS_MARK_LIGATURE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_MARK_LIGATURE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_MARK_LIGATURE_TEST_C_SOURCES "")
foreach(MODULE gpos_mark_ligature_match_cases gpos_mark_ligature_error_cases gpos_mark_ligature_stress_cases
    gpos_mark_ligature_font_cases gpos_mark_ligature_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/opentype/position/gpos_mark_ligature_contracts.sats tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GPOS_MARK_LIGATURE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gpos_mark_ligature_conformance EXCLUDE_FROM_ALL ${GPOS_MARK_LIGATURE_C_SOURCES} ${GPOS_VALUE_C_SOURCES}
  ${GPOS_MARK_SHARED_C_SOURCES} ${GPOS_MARK_LIGATURE_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gpos_mark_ligature_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gpos_mark_ligature_conformance m)
add_test(NAME gpos_mark_ligature_conformance COMMAND gpos_mark_ligature_conformance)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME gpos_mark_ligature_font_conformance COMMAND gpos_mark_ligature_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
add_test(NAME gpos_ligature_groups_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_gpos_ligature_groups_error.cmake")
