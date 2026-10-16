file(GLOB_RECURSE GSUB_LIGATURE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gsub_ligature_*.dats")
set(GSUB_LIGATURE_C_SOURCES "")
foreach(SOURCE ${GSUB_LIGATURE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GSUB_LIGATURE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GSUB_LIGATURE_TEST_C_SOURCES "")
foreach(MODULE gsub_ligature_priority_cases gsub_ligature_error_cases gsub_ligature_stress_cases
    gsub_ligature_font_cases gsub_ligature_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/opentype/substitution/gsub_ligature_contracts.sats tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GSUB_LIGATURE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gsub_ligature_conformance EXCLUDE_FROM_ALL ${GSUB_LIGATURE_C_SOURCES}
  ${GSUB_LIGATURE_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gsub_ligature_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gsub_ligature_conformance m)
add_test(NAME gsub_ligature_conformance COMMAND gsub_ligature_conformance)
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME gsub_ligature_font_conformance COMMAND gsub_ligature_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
