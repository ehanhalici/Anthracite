file(GLOB GLYPH_RUN_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/glyph_run_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/glyph_core_draft.dats")
set(GLYPH_RUN_C_SOURCES "")
foreach(SOURCE ${GLYPH_RUN_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GLYPH_RUN_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(GLYPH_RUN_TEST_C_SOURCES "")
foreach(MODULE glyph_run_fixture glyph_run_basic_cases glyph_run_ligature_cases glyph_run_position_cases
    glyph_run_stress_cases glyph_run_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/glyph_run_contracts.sats ${ATS_INTERFACES})
  list(APPEND GLYPH_RUN_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(glyph_run_conformance EXCLUDE_FROM_ALL ${GLYPH_RUN_C_SOURCES} ${GLYPH_RUN_TEST_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c")
target_compile_definitions(glyph_run_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(glyph_run_conformance m)
add_test(NAME glyph_run_conformance COMMAND glyph_run_conformance)
add_test(NAME glyph_run_phase_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_glyph_run_phase_error.cmake")
