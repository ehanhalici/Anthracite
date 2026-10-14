set(NATIVE_PIPELINE_TEST_C_SOURCES "")
foreach(MODULE native_pipeline_bytes native_pipeline_ranges native_pipeline_contexts native_pipeline_shapes
    native_pipeline_coverage native_pipeline_joined native_pipeline_note_walk native_pipeline_note_read native_pipeline_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/native_pipeline_contracts.sats tests/native_pipeline_test.hats
      tests/native_pipeline_note.hats tests/native_pipeline_note.sats ${ATS_INTERFACES})
  list(APPEND NATIVE_PIPELINE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(native_text_shape_conformance EXCLUDE_FROM_ALL ${NATIVE_PIPELINE_TEST_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c")
target_compile_definitions(native_text_shape_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(native_text_shape_conformance native_text_engine)
add_dependencies(native_text_shape_conformance unicode_data unicode_properties normalization_data script_data)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME native_text_shape_conformance COMMAND native_text_shape_conformance
    "${CMAKE_CURRENT_BINARY_DIR}" "${UCD_SOURCE}" "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
