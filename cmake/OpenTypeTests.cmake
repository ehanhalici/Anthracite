file(GLOB OT_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/opentype_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/gdef_*.dats")
set(OT_C_SOURCES "")
foreach(SOURCE ${OT_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND OT_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(OT_TEST_MODULES opentype_fixture opentype_coverage_cases opentype_class_cases
  opentype_device_cases opentype_mutations opentype_stress opentype_conformance)
set(OT_TEST_C_SOURCES "")
foreach(MODULE ${OT_TEST_MODULES})
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/opentype_fixture.sats tests/opentype_contracts.sats ${ATS_INTERFACES})
  list(APPEND OT_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(opentype_conformance EXCLUDE_FROM_ALL ${OT_C_SOURCES} ${OT_TEST_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(opentype_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(opentype_conformance m)
add_test(NAME opentype_conformance COMMAND opentype_conformance)
find_program(ANTHRACITE_OT_PATSOPT patsopt REQUIRED)
add_test(NAME opentype_descriptor_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_opentype_descriptor_error.cmake")
foreach(MODULE gdef_metadata_cases gdef_flag_cases gdef_mark_cases gdef_font_cases gdef_conformance)
  add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/gdef_contracts.sats tests/opentype_fixture.sats ${ATS_INTERFACES})
endforeach()
add_executable(gdef_conformance EXCLUDE_FROM_ALL ${OT_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/font_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/opentype_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/gdef_metadata_cases_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/gdef_flag_cases_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/gdef_mark_cases_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/gdef_font_cases_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/gdef_conformance_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(gdef_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(gdef_conformance m)
add_test(NAME gdef_conformance COMMAND gdef_conformance)
set(ANTHRACITE_OT_LATIN_TTF "" CACHE FILEPATH "DejaVu Sans Mono static test font")
set(ANTHRACITE_OT_ARABIC_TTF "" CACHE FILEPATH "Noto Naskh Arabic static test font")
if(EXISTS "${ANTHRACITE_OT_LATIN_TTF}" AND EXISTS "${ANTHRACITE_OT_ARABIC_TTF}")
  add_test(NAME gdef_font_conformance COMMAND gdef_conformance
    "${ANTHRACITE_OT_LATIN_TTF}" "${ANTHRACITE_OT_ARABIC_TTF}")
endif()
