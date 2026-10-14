file(GLOB LINE_ENGINE_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_text/line_*.dats")
set(LINE_ENGINE_C_SOURCES "")
foreach(SOURCE ${LINE_ENGINE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND LINE_ENGINE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
foreach(MODULE line_fixture line_conformance_cases line_conformance line_contracts line_contract_units line_contract_stress)
  add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c" -d "${CMAKE_SOURCE_DIR}/tests/${MODULE}.dats"
    DEPENDS "tests/${MODULE}.dats" tests/line_fixture.sats tests/line_conformance.sats tests/line_contracts.sats ${ATS_INTERFACES})
endforeach()
add_executable(line_conformance EXCLUDE_FROM_ALL ${LINE_ENGINE_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/category_property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_conformance_cases_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_conformance_dats.c")
target_compile_definitions(line_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(line_conformance m)
add_dependencies(line_conformance unicode_data unicode_properties)
add_test(NAME line_conformance COMMAND line_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-line.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-east-asian.bin"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-category.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin"
  "${UCD_SOURCE}/auxiliary/LineBreakTest.txt")
add_executable(line_contracts EXCLUDE_FROM_ALL ${LINE_ENGINE_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/category_property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_contracts_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_contract_units_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_contract_stress_dats.c")
target_compile_definitions(line_contracts PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(line_contracts m)
add_dependencies(line_contracts unicode_data unicode_properties)
add_test(NAME line_contracts COMMAND line_contracts
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-line.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-east-asian.bin"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-category.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin")
find_program(ANTHRACITE_LINE_PATSOPT patsopt REQUIRED)
add_test(NAME line_domain_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_LINE_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_line_domain_error.cmake")
