file(GLOB_RECURSE ARABIC_MARKS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_text/arabic_marks_*.dats")
set(ARABIC_MARKS_C_SOURCES "")
foreach(SOURCE ${ARABIC_MARKS_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND ARABIC_MARKS_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(ARABIC_MARKS_TEST_C_SOURCES "")
foreach(MODULE arabic_marks_fixture arabic_marks_cases arabic_marks_stress arabic_marks_properties arabic_marks_conformance)
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  add_custom_command(OUTPUT "${OUTPUT}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${OUTPUT}" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/text/arabic/marks/arabic_marks_contracts.sats tests/text/arabic/marks/arabic_marks_test.hats ${ATS_INTERFACES})
  list(APPEND ARABIC_MARKS_TEST_C_SOURCES "${OUTPUT}")
endforeach()
add_executable(arabic_marks_conformance EXCLUDE_FROM_ALL ${ARABIC_MARKS_C_SOURCES} ${ARABIC_MARKS_TEST_C_SOURCES}
  ${NORMALIZATION_C_SOURCES} ${UTF8_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c")
target_compile_definitions(arabic_marks_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(arabic_marks_conformance m)
add_dependencies(arabic_marks_conformance unicode_properties normalization_data)
add_test(NAME arabic_marks_conformance COMMAND arabic_marks_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-modifier-mark.bin")
add_test(NAME native_shape_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_native_shape_error.cmake")
