file(GLOB_RECURSE OT_COV_CACHE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_cov_cache_*.dats")
set(OT_COV_CACHE_C_SOURCES "")
foreach(SOURCE ${OT_COV_CACHE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND OT_COV_CACHE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
file(GLOB_RECURSE GSUB_REVERSE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gsub_reverse_*.dats")
set(GSUB_REVERSE_C_SOURCES "")
foreach(SOURCE ${GSUB_REVERSE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GSUB_REVERSE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GSUB_REVERSE_TEST_C_SOURCES "")
foreach(MODULE gsub_reverse_context_cases gsub_reverse_error_cases gsub_reverse_cache_cases
    gsub_reverse_stress_cases gsub_reverse_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/font/opentype/substitution/gsub_reverse_contracts.sats tests/font/opentype/tables/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GSUB_REVERSE_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gsub_reverse_conformance EXCLUDE_FROM_ALL ${GSUB_REVERSE_C_SOURCES} ${OT_COV_CACHE_C_SOURCES}
  ${GSUB_REVERSE_TEST_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gsub_reverse_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gsub_reverse_conformance m)
add_test(NAME gsub_reverse_conformance COMMAND gsub_reverse_conformance)
add_test(NAME ot_cov_cache_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_ot_cov_cache_type_error.cmake")
