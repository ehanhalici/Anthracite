file(GLOB GPOS_PAIR_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/gpos_pair_*.dats")
set(GPOS_PAIR_C_SOURCES "")
foreach(SOURCE ${GPOS_PAIR_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GPOS_PAIR_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GPOS_PAIR_TEST_C_SOURCES "")
foreach(MODULE gpos_pair_fixture gpos_pair_match_cases gpos_pair_error_cases
    gpos_pair_stress_cases gpos_pair_font_cases gpos_pair_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gpos_pair_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
  list(APPEND GPOS_PAIR_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(gpos_pair_conformance EXCLUDE_FROM_ALL ${GPOS_PAIR_C_SOURCES} ${GPOS_VALUE_C_SOURCES} ${OT_LAYOUT_C_SOURCES}
  ${GPOS_PAIR_TEST_C_SOURCES} ${OT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_sources(gpos_pair_conformance PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c")
target_compile_definitions(gpos_pair_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gpos_pair_conformance m)
add_test(NAME gpos_pair_conformance COMMAND gpos_pair_conformance)
set(ANTHRACITE_OT_KERN_TTF "" CACHE FILEPATH "DejaVu Sans static PairPos test font")
if(EXISTS "${ANTHRACITE_OT_KERN_TTF}")
  add_test(NAME gpos_pair_font_conformance COMMAND gpos_pair_conformance "${ANTHRACITE_OT_KERN_TTF}")
endif()
add_test(NAME gpos_value_cache_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_gpos_value_cache_error.cmake")
