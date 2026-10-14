file(GLOB NATIVE_TEXT_ASSETS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/native_text_assets_*.dats")
set(NATIVE_TEXT_ASSETS_C_SOURCES "")
foreach(SOURCE ${NATIVE_TEXT_ASSETS_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND NATIVE_TEXT_ASSETS_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(NATIVE_ASSETS_TEST_C "${CMAKE_CURRENT_BINARY_DIR}/native_text_assets_conformance_dats.c")
add_custom_command(OUTPUT "${NATIVE_ASSETS_TEST_C}"
  COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
    -d "${CMAKE_SOURCE_DIR}/tests/native_text_assets_conformance.dats"
  COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
    -o "${NATIVE_ASSETS_TEST_C}" -d "${CMAKE_SOURCE_DIR}/tests/native_text_assets_conformance.dats"
  DEPENDS tests/native_text_assets_conformance.dats ${ATS_INTERFACES})
add_executable(native_text_assets_conformance EXCLUDE_FROM_ALL ${NATIVE_TEXT_ASSETS_C_SOURCES}
  "${NATIVE_ASSETS_TEST_C}" ${SCRIPT_C_SOURCES} ${NORMALIZATION_C_SOURCES} ${UTF8_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/native_shape_data_dispose_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_bracket_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_bracket_lookup_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_mirror_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_mirror_lookup_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c")
target_compile_definitions(native_text_assets_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(native_text_assets_conformance m)
add_dependencies(native_text_assets_conformance unicode_data unicode_properties normalization_data script_data)
add_test(NAME native_text_assets_conformance COMMAND native_text_assets_conformance
  "${CMAKE_CURRENT_BINARY_DIR}" "${UCD_SOURCE}")
