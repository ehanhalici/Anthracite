file(GLOB_RECURSE GLYPH_POSITION_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/glyph_position_*.dats")
set(GLYPH_POSITION_C_SOURCES "")
foreach(SOURCE ${GLYPH_POSITION_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GLYPH_POSITION_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GLYPH_POSITION_TEST_C_SOURCES "")
file(GLOB_RECURSE NATIVE_SHAPE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/native_shape_*.dats")
foreach(SOURCE ${NATIVE_SHAPE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GLYPH_POSITION_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
foreach(MODULE glyph_position_fixture glyph_position_scale_cases glyph_position_single_cases
    glyph_position_pair_cases glyph_position_cursive_cases glyph_position_mark_cases glyph_position_graph_cases glyph_position_font_fixture
    glyph_position_font_apply glyph_position_font_cases glyph_position_schedule_font glyph_position_lookup_cases glyph_position_lookup_pair_cases
    glyph_position_lookup_mark_cases glyph_position_lookup_error_cases font_run_measure_cases glyph_normalized_cases
    glyph_position_stage_fixture glyph_position_stage_cases glyph_position_context_fixture glyph_position_context_basic
    glyph_position_context_nested glyph_position_context_rollback glyph_position_context_cache
    glyph_position_context_encodings glyph_position_context_stress glyph_position_context_order
    native_shape_data native_shape_examples native_shape_faces native_shape_suite native_shape_script_cases glyph_position_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/glyph/position/glyph_position_contracts.sats tests/font/glyph/position/glyph_position_context_contracts.sats
      tests/font/glyph/position/glyph_position_font_contracts.sats
      tests/font/native/shape/native_shape_contracts.sats tests/font/native/shape/native_shape_test.hats
      tests/font/glyph/position/glyph_position_context_test.hats ${ATS_INTERFACES})
  list(APPEND GLYPH_POSITION_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(glyph_position_conformance EXCLUDE_FROM_ALL ${GLYPH_POSITION_C_SOURCES} ${POSITION_LOOKUP_C_SOURCES}
  ${GLYPH_POSITION_TEST_C_SOURCES} ${GLYPH_RUN_C_SOURCES} ${GLYPH_METADATA_C_SOURCES}
  ${GPOS_SINGLE_C_SOURCES} ${GPOS_PAIR_C_SOURCES} ${GPOS_CURSIVE_C_SOURCES} ${GPOS_MARK_MATRIX_C_SOURCES}
  ${GPOS_MARK_LIGATURE_C_SOURCES} ${GPOS_MARK_SHARED_C_SOURCES} ${GPOS_VALUE_C_SOURCES}
  ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES} ${OT_CONTEXT_C_SOURCES} ${OT_COV_CACHE_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_pass_selection_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_neighbor_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_neighbor_checks_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_neighbor_search_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_run_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_sources(glyph_position_conformance PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/font_run_measure_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_run_geometry_dats.c" ${NORMALIZATION_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c")
target_compile_definitions(glyph_position_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(glyph_position_conformance m)
target_sources(glyph_position_conformance PRIVATE ${GLYPH_NOMINAL_C_SOURCES} ${UTF8_C_SOURCES}
  ${GSUB_SEQUENCE_C_SOURCES} ${SEQUENCE_LOOKUP_C_SOURCES} ${GSUB_SINGLE_C_SOURCES} ${SINGLE_LOOKUP_C_SOURCES}
  ${GLYPH_PASS_C_SOURCES} ${ARABIC_JOIN_C_SOURCES} ${GSUB_LIGATURE_C_SOURCES} ${LIGATION_LOOKUP_C_SOURCES}
  ${GSUB_REVERSE_C_SOURCES} ${REVERSE_LOOKUP_C_SOURCES}
  ${SUBSTITUTION_GRAPH_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/grapheme_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_nominal_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_nominal_arabic_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_nominal_arabic_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_pass_fixture_dats.c")
target_sources(glyph_position_conformance PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/ot_context_fixture_dats.c")
add_dependencies(glyph_position_conformance unicode_data unicode_properties normalization_data)
add_test(NAME glyph_position_conformance COMMAND glyph_position_conformance)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME glyph_position_font_conformance COMMAND glyph_position_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-joining.bin")
  add_test(NAME glyph_normalized_font_conformance COMMAND glyph_position_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-joining.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin")
  add_test(NAME native_shape_font_conformance COMMAND glyph_position_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-joining.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18-category.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-ignorable.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18-modifier-mark.bin")
endif()
add_test(NAME glyph_position_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_glyph_position_error.cmake")
