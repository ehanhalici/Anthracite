file(GLOB_RECURSE OT_LAYOUT_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_layout_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/ot_shape_*.dats" "${CMAKE_SOURCE_DIR}/src/data_font/ot_feature_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/ot_item_*.dats")
set(OT_LAYOUT_C_SOURCES "")
foreach(SOURCE ${OT_LAYOUT_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND OT_LAYOUT_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(OT_LAYOUT_TEST_C_SOURCES "")
foreach(MODULE ot_layout_fixture ot_layout_structure_cases ot_layout_selection_cases
    ot_layout_extension_cases ot_layout_stage_cases
    ot_layout_fallback_cases
    ot_layout_flag_cases ot_layout_set_cases ot_layout_capacity_cases ot_layout_stress_cases
    ot_layout_params_cases
    ot_layout_font_oracle ot_layout_font_cases ot_layout_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/opentype/layout/ot_layout_contracts.sats tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND OT_LAYOUT_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(ot_layout_conformance EXCLUDE_FROM_ALL ${OT_LAYOUT_C_SOURCES} ${OT_C_SOURCES}
  ${OT_LAYOUT_TEST_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(ot_layout_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(ot_layout_conformance m)
add_test(NAME ot_layout_conformance COMMAND ot_layout_conformance)
add_test(NAME ot_layout_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_ot_layout_type_error.cmake")
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME ot_layout_font_conformance COMMAND ot_layout_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
