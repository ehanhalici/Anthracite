file(GLOB GPOS_VALUE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_value_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/gpos_adjustment_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/gpos_anchor_*.dats")
set(GPOS_VALUE_C_SOURCES "")
foreach(SOURCE ${GPOS_VALUE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_VALUE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_VALUE_TEST_C_SOURCES "")
foreach(MODULE gpos_format_cases gpos_value_fixture gpos_value_cases
    gpos_anchor_cases gpos_value_error_cases gpos_value_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gpos_value_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GPOS_VALUE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gpos_value_conformance EXCLUDE_FROM_ALL ${GPOS_VALUE_C_SOURCES}
  ${GPOS_VALUE_TEST_C_SOURCES} ${OT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gpos_value_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gpos_value_conformance m)
add_test(NAME gpos_value_conformance COMMAND gpos_value_conformance)
