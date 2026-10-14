foreach(TEST_MODULE font_fixture sfnt_conformance component_conformance font_render_conformance)
  add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${TEST_MODULE}_dats.c"
    COMMAND patsopt -tc -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -IATS ${CMAKE_CURRENT_SOURCE_DIR}/tests
      -d "${CMAKE_CURRENT_SOURCE_DIR}/tests/${TEST_MODULE}.dats"
    COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -IATS ${CMAKE_CURRENT_SOURCE_DIR}/tests
      -o "${CMAKE_CURRENT_BINARY_DIR}/${TEST_MODULE}_dats.c"
      -d "${CMAKE_CURRENT_SOURCE_DIR}/tests/${TEST_MODULE}.dats"
    DEPENDS "tests/${TEST_MODULE}.dats" tests/font_fixture.sats tests/font_native_contracts.sats ${ATS_INTERFACES})
endforeach()
set(FONT_GLYPH_ID_TEST_C_SOURCES "")
foreach(MODULE font_glyph_id_fixture font_glyph_id_primary font_glyph_id_fallback font_glyph_id_domains
    font_glyph_id_cache font_glyph_id_collision font_glyph_id_atlas font_gl_airlock
    font_run_render_fixture font_run_render_reference font_run_render_cases font_native_owner_setup font_native_owner_cases font_span_owner_cases
    font_span_boundary_cases font_text_service_cases font_span_partition_cases font_text_note_cases font_text_abi_airlock
    font_span_missing_cases font_registry_cases doc_text_navigation_cases font_text_cache_cases event_repaint_cases font_text_metrics_cases visual_layout_cases source_edit_cases)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/font_glyph_id_contracts.sats tests/font_gl_airlock.sats tests/font_run_render_contracts.sats
      tests/font_native_contracts.sats tests/font_native_test.hats tests/native_pipeline_contracts.sats tests/native_pipeline_test.hats
      tests/font_text_abi_airlock.sats ${ATS_INTERFACES})
  list(APPEND FONT_GLYPH_ID_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(sfnt_conformance EXCLUDE_FROM_ALL
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_conformance_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(sfnt_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(sfnt_conformance m)
add_test(NAME sfnt_conformance COMMAND sfnt_conformance)
add_executable(component_conformance EXCLUDE_FROM_ALL
  "${CMAKE_CURRENT_BINARY_DIR}/component_conformance_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/glyph_component_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(component_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(component_conformance m)
add_test(NAME component_conformance COMMAND component_conformance)
set(FONT_RENDER_SOURCES ${GENERATED_C_SOURCES})
list(REMOVE_ITEM FONT_RENDER_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/main_dats.c")
add_executable(font_render_conformance EXCLUDE_FROM_ALL ${FONT_RENDER_SOURCES} ${FONT_GLYPH_ID_TEST_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/font_render_conformance_dats.c")
add_dependencies(font_render_conformance unicode_data unicode_properties normalization_data script_data)
target_compile_definitions(font_render_conformance PRIVATE ATS_MEMALLOC_LIBC
  "ANTHRACITE_UNIFONT=\"${CMAKE_SOURCE_DIR}/src/data_font/unifont.bin\"")
target_link_libraries(font_render_conformance m ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME source_edit_conformance COMMAND font_render_conformance
  "${CMAKE_CURRENT_BINARY_DIR}" "${UCD_SOURCE}")
