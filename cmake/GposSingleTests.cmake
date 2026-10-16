file(GLOB_RECURSE GPOS_SINGLE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_single_*.dats")
set(GPOS_SINGLE_C_SOURCES "")
foreach(SOURCE ${GPOS_SINGLE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_SINGLE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_SINGLE_TEST_C_SOURCES "")
foreach(MODULE gpos_single_match_cases gpos_single_error_cases gpos_single_stress_cases
    gpos_single_font_cases gpos_single_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/opentype/position/gpos_single_contracts.sats tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GPOS_SINGLE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gpos_single_conformance EXCLUDE_FROM_ALL ${GPOS_SINGLE_C_SOURCES} ${GPOS_VALUE_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  ${GPOS_SINGLE_TEST_C_SOURCES} ${OT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_sources(gpos_single_conformance PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c")
target_compile_definitions(gpos_single_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gpos_single_conformance m)
add_test(NAME gpos_single_conformance COMMAND gpos_single_conformance)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}")
  add_test(NAME gpos_single_font_conformance COMMAND gpos_single_conformance "${ANTHRACITE_OT_LATIN_TTF}")
endif()
