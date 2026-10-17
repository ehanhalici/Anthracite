file(GLOB_RECURSE GLYPH_PASS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/glyph_pass_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/glyph_neighbor*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/glyph_expansion_*.dats")
file(GLOB_RECURSE GLYPH_CONTEXT_ARENA_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/glyph_context_arena_*.dats")
list(APPEND GLYPH_PASS_SOURCES ${GLYPH_CONTEXT_ARENA_SOURCES})
file(GLOB_RECURSE GLYPH_SUBSTITUTION_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/glyph_substitution_*.dats")
list(APPEND GLYPH_PASS_SOURCES ${GLYPH_SUBSTITUTION_SOURCES})
set(GLYPH_PASS_C_SOURCES "")
foreach(SOURCE ${GLYPH_PASS_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GLYPH_PASS_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GLYPH_PASS_TEST_C_SOURCES "")
foreach(MODULE glyph_pass_fixture glyph_pass_basic_cases glyph_pass_sparse_cases glyph_pass_stress_cases
    glyph_pass_font_run glyph_pass_font_cases ot_single_lookup_cases ot_single_lookup_stress
    glyph_lookup_fixture glyph_lookup_filters glyph_lookup_rejections glyph_lookup_properties
    glyph_lookup_capacity glyph_neighbor_cases glyph_neighbor_sparse glyph_neighbor_stress
    glyph_neighbor_rejections glyph_sequence_fixture glyph_sequence_cache glyph_sequence_multiple
    glyph_sequence_alternate glyph_sequence_filters glyph_sequence_rejections glyph_sequence_stress
    glyph_sequence_font_apply glyph_sequence_font_cases glyph_ligation_fixture glyph_ligation_basic
    glyph_ligation_associations glyph_ligation_masks glyph_ligation_cache glyph_ligation_font
    glyph_window_fixture glyph_window_basic glyph_window_masks glyph_window_rejections glyph_window_associations
    glyph_reverse_fixture glyph_reverse_basic glyph_reverse_cache glyph_reverse_rollback glyph_reverse_masks
    glyph_reverse_stress glyph_substitution_cache_fixture glyph_substitution_cache_contexts
    glyph_substitution_cache_errors glyph_substitution_cache_fonts glyph_context_arena_edits
    glyph_context_arena_rejections glyph_context_arena_stress glyph_substitution_engine_fixture
    glyph_substitution_engine_encodings glyph_substitution_engine_mutations glyph_substitution_engine_rollback
    glyph_substitution_engine_priority glyph_substitution_engine_stress glyph_substitution_stage_fixture
    glyph_substitution_stage_cases glyph_unicode_fixture glyph_unicode_properties
    glyph_unicode_substitution ot_shape_fixture ot_shape_selection_cases ot_shape_execution_cases
    ot_shape_font_cases glyph_pass_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/glyph/pass/glyph_pass_contracts.sats tests/font/glyph/run/glyph_run_contracts.sats
      tests/font/glyph/core/glyph_lookup_contracts.sats tests/font/glyph/core/glyph_sequence_contracts.sats tests/font/glyph/core/glyph_nominal_contracts.sats
      tests/font/opentype/tables/opentype_fixture.sats tests/font/glyph/core/glyph_window_contracts.sats tests/font/glyph/core/glyph_window_test.hats
      tests/font/glyph/core/glyph_reverse_contracts.sats tests/font/glyph/core/glyph_reverse_test.hats
      tests/font/glyph/substitution/glyph_substitution_cache_contracts.sats tests/font/glyph/substitution/glyph_substitution_cache_test.hats
      tests/font/glyph/context/glyph_context_arena_contracts.sats tests/font/glyph/context/glyph_context_arena_test.hats
      tests/font/glyph/substitution/glyph_substitution_engine_contracts.sats tests/font/glyph/substitution/glyph_substitution_engine_test.hats
      tests/font/glyph/substitution/glyph_substitution_stage_contracts.sats tests/font/glyph/substitution/glyph_substitution_stage_test.hats
      tests/font/glyph/core/glyph_unicode_contracts.sats tests/font/glyph/core/glyph_unicode_test.hats
      tests/font/opentype/shape/ot_shape_contracts.sats tests/font/opentype/shape/ot_shape_test.hats ${ATS_INTERFACES})
  list(APPEND GLYPH_PASS_TEST_C_SOURCES "${OUTPUT}")
endforeach()
foreach(MODULE glyph_nominal_fixture glyph_nominal_mixed glyph_nominal_malformed glyph_nominal_stress
    glyph_nominal_arabic_fixture glyph_nominal_arabic glyph_nominal_font_cases glyph_nominal_note)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/glyph/core/glyph_nominal_contracts.sats tests/font/glyph/pass/glyph_pass_contracts.sats
      tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GLYPH_PASS_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(glyph_pass_conformance EXCLUDE_FROM_ALL ${GLYPH_PASS_C_SOURCES} ${GLYPH_RUN_C_SOURCES}
  ${GLYPH_PASS_TEST_C_SOURCES} ${GSUB_SINGLE_C_SOURCES} ${SINGLE_LOOKUP_C_SOURCES}
  ${GSUB_SEQUENCE_C_SOURCES} ${SEQUENCE_LOOKUP_C_SOURCES} ${GSUB_LIGATURE_C_SOURCES} ${LIGATION_LOOKUP_C_SOURCES}
  ${GLYPH_NOMINAL_C_SOURCES} ${UTF8_C_SOURCES} ${GSUB_REVERSE_C_SOURCES} ${REVERSE_LOOKUP_C_SOURCES}
  ${SUBSTITUTION_GRAPH_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/grapheme_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c"
  ${GLYPH_METADATA_C_SOURCES} ${OT_C_SOURCES} ${OT_CONTEXT_C_SOURCES} ${OT_COV_CACHE_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_run_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/gsub_single_font_oracle_dats.c" ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/ot_context_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(glyph_pass_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(glyph_pass_conformance m)
add_test(NAME glyph_pass_conformance COMMAND glyph_pass_conformance)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME glyph_pass_font_conformance COMMAND glyph_pass_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME glyph_nominal_font_conformance COMMAND glyph_pass_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-joining.bin")
  add_test(NAME glyph_unicode_font_conformance COMMAND glyph_pass_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-joining.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18-category.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-ignorable.bin")
endif()
