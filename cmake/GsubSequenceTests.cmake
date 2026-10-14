file(GLOB GSUB_SEQUENCE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gsub_sequence_*.dats")
set(GSUB_SEQUENCE_C_SOURCES "")
foreach(SOURCE ${GSUB_SEQUENCE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GSUB_SEQUENCE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GSUB_SEQUENCE_TEST_C_SOURCES "")
foreach(MODULE gsub_sequence_format_cases gsub_sequence_error_cases gsub_sequence_stress_cases
    gsub_sequence_extension_cases gsub_sequence_font_cases gsub_sequence_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gsub_sequence_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GSUB_SEQUENCE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gsub_sequence_conformance EXCLUDE_FROM_ALL ${GSUB_SEQUENCE_C_SOURCES}
  ${GSUB_SINGLE_C_SOURCES} ${GSUB_SEQUENCE_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gsub_sequence_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gsub_sequence_conformance m)
add_test(NAME gsub_sequence_conformance COMMAND gsub_sequence_conformance)
if(EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME gsub_sequence_font_conformance COMMAND gsub_sequence_conformance "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
