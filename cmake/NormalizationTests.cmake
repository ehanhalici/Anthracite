foreach(MODULE scalar_fixture normalization_fixture normalization_stable normalization_conformance normalization_contracts normalization_provenance normalization_source_contracts normalization_blob_contracts)
  add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/text/utf8/scalar_fixture.sats tests/text/normalization/normalization_fixture.sats tests/text/normalization/normalization_contracts.sats ${ATS_INTERFACES})
endforeach()
add_executable(normalization_conformance EXCLUDE_FROM_ALL ${NORMALIZATION_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/scalar_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/normalization_fixture_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/normalization_stable_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/normalization_conformance_dats.c")
target_compile_definitions(normalization_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(normalization_conformance m)

add_executable(normalization_contracts EXCLUDE_FROM_ALL ${NORMALIZATION_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/normalization_contracts_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/normalization_provenance_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/normalization_source_contracts_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/normalization_blob_contracts_dats.c")
target_compile_definitions(normalization_contracts PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(normalization_contracts m)
add_dependencies(normalization_contracts normalization_data)
add_test(NAME normalization_contracts COMMAND normalization_contracts "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin")
add_dependencies(normalization_conformance normalization_data)
add_test(NAME normalization_conformance COMMAND normalization_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin" "${UCD_SOURCE}/NormalizationTest.txt")
find_program(ANTHRACITE_NORMALIZATION_PATSOPT patsopt REQUIRED)
add_test(NAME normalization_phase_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_NORMALIZATION_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_normalization_phase_error.cmake")
