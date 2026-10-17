file(GLOB_RECURSE NATIVE_TEXT_ANALYSIS_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/src/data_font/native_text_analysis_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/native_text_items_*.dats")
set(NATIVE_TEXT_ANALYSIS_C_SOURCES "")
foreach(SOURCE ${NATIVE_TEXT_ANALYSIS_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND NATIVE_TEXT_ANALYSIS_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(NATIVE_ANALYSIS_TEST_C "${CMAKE_CURRENT_BINARY_DIR}/native_text_analysis_conformance_dats.c")
add_custom_command(OUTPUT "${NATIVE_ANALYSIS_TEST_C}"
  COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
    -d "${CMAKE_SOURCE_DIR}/tests/font/native/text/native_text_analysis_conformance.dats"
  COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
    -o "${NATIVE_ANALYSIS_TEST_C}" -d "${CMAKE_SOURCE_DIR}/tests/font/native/text/native_text_analysis_conformance.dats"
  DEPENDS tests/font/native/text/native_text_analysis_conformance.dats tests/font/native/text/native_analysis_window_cases.hats tests/font/native/text/native_text_item_cases.sats ${ATS_INTERFACES})
set(NATIVE_ITEM_TEST_C "${CMAKE_CURRENT_BINARY_DIR}/native_text_item_cases_dats.c")
add_custom_command(OUTPUT "${NATIVE_ITEM_TEST_C}"
  COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
    -d "${CMAKE_SOURCE_DIR}/tests/font/native/text/native_text_item_cases.dats"
  COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
    -o "${NATIVE_ITEM_TEST_C}" -d "${CMAKE_SOURCE_DIR}/tests/font/native/text/native_text_item_cases.dats"
  DEPENDS tests/font/native/text/native_text_item_cases.dats tests/font/native/text/native_text_item_cases.sats ${ATS_INTERFACES})
add_executable(native_text_analysis_conformance EXCLUDE_FROM_ALL ${NATIVE_TEXT_ANALYSIS_C_SOURCES}
  ${NATIVE_TEXT_ASSETS_C_SOURCES} "${NATIVE_ANALYSIS_TEST_C}" "${NATIVE_ITEM_TEST_C}"
  ${SCRIPT_C_SOURCES} ${SCRIPT_ITEMS_C_SOURCES} ${NORMALIZATION_C_SOURCES} ${BIDI_C_SOURCES}
  ${UTF8_C_SOURCES} ${LINE_ENGINE_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/native_shape_data_dispose_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/grapheme_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/category_property_symbols_dats.c")
target_compile_definitions(native_text_analysis_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(native_text_analysis_conformance m)
add_dependencies(native_text_analysis_conformance unicode_data unicode_properties normalization_data script_data)
add_test(NAME native_text_analysis_conformance COMMAND native_text_analysis_conformance
  "${CMAKE_CURRENT_BINARY_DIR}" "${UCD_SOURCE}")
