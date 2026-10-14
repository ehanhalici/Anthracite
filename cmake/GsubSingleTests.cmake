file(GLOB GSUB_SINGLE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gsub_single*.dats")
set(GSUB_SINGLE_C_SOURCES "")
foreach(SOURCE ${GSUB_SINGLE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GSUB_SINGLE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GSUB_SINGLE_TEST_C_SOURCES "")
foreach(MODULE gsub_single_fixture gsub_single_format_cases gsub_single_mutation_cases
    gsub_single_stress_cases gsub_single_font_oracle gsub_single_font_cases gsub_single_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gsub_single_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GSUB_SINGLE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gsub_single_conformance EXCLUDE_FROM_ALL ${GSUB_SINGLE_C_SOURCES}
  ${GSUB_SINGLE_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gsub_single_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gsub_single_conformance m)
add_test(NAME gsub_single_conformance COMMAND gsub_single_conformance)
add_test(NAME gsub_single_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_gsub_single_type_error.cmake")
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME gsub_single_font_conformance COMMAND gsub_single_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
