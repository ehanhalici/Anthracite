# Independently compiled UTF-8 responsibilities are linked as one source set.
file(GLOB_RECURSE UTF8_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_text/utf8*.dats")
set(UTF8_C_SOURCES "")
foreach(SOURCE ${UTF8_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND UTF8_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(UTF8_TEST_C_SOURCES "")
foreach(MODULE utf8_encoding_fixture utf8_scalar_contracts utf8_storage_contracts utf8_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/text/utf8/utf8_contracts.sats ${ATS_INTERFACES})
  list(APPEND UTF8_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(utf8_conformance EXCLUDE_FROM_ALL ${UTF8_C_SOURCES} ${UTF8_TEST_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c")
target_compile_definitions(utf8_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(utf8_conformance m)
add_test(NAME utf8_conformance COMMAND utf8_conformance)
find_program(ANTHRACITE_UTF8_PATSOPT patsopt REQUIRED)
add_test(NAME utf8_flat_step COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_UTF8_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_utf8_flat_step.cmake")
