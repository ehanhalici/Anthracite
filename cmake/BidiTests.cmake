# CPU-only Unicode conformance. No graphics/font discovery dependency.
set(BIDI_C_SOURCES "")
foreach(ATS_FILE IN LISTS ATS_SOURCES)
  if(ATS_FILE MATCHES "/bidi_[^/]+\\.dats$" OR ATS_FILE MATCHES "/unicode_sort\\.dats$")
    get_filename_component(MODULE "${ATS_FILE}" NAME_WE)
    list(APPEND BIDI_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  endif()
endforeach()
foreach(MODULE bidi_fixture_parse bidi_fixture_check bidi_character_conformance bidi_class_fixture bidi_class_check bidi_class_conformance bidi_document_conformance unicode_contracts)
  add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -d "${ANTHRACITE_TEST_${MODULE}}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -IATS "${CMAKE_SOURCE_DIR}/tests"
      -o "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c" -d "${ANTHRACITE_TEST_${MODULE}}"
    DEPENDS "${ANTHRACITE_TEST_${MODULE}}" tests/text/bidi/bidi_fixture.sats tests/text/bidi/bidi_class_fixture.sats ${ATS_INTERFACES})
endforeach()
add_executable(bidi_character_conformance EXCLUDE_FROM_ALL ${BIDI_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_fixture_parse_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_fixture_check_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_character_conformance_dats.c")
target_compile_definitions(bidi_character_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(bidi_character_conformance m)
add_dependencies(bidi_character_conformance unicode_properties)
add_test(NAME bidi_character_conformance COMMAND bidi_character_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-bidi.bin" "${UCD_SOURCE}/BidiBrackets.txt"
  "${UCD_SOURCE}/BidiCharacterTest.txt")

add_executable(bidi_class_conformance EXCLUDE_FROM_ALL ${BIDI_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/category_property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_fixture_parse_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_fixture_check_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_class_fixture_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_class_check_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_class_conformance_dats.c")
target_compile_definitions(bidi_class_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(bidi_class_conformance m)

add_executable(bidi_document_conformance EXCLUDE_FROM_ALL ${BIDI_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  ${UTF8_C_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_fixture_parse_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_document_conformance_dats.c")
target_compile_definitions(bidi_document_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(bidi_document_conformance m)
add_dependencies(bidi_document_conformance unicode_properties)
add_test(NAME bidi_document_conformance COMMAND bidi_document_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-bidi.bin" "${UCD_SOURCE}/BidiBrackets.txt")
add_test(NAME bidi_class_conformance COMMAND bidi_class_conformance
  "${UCD_SOURCE}/BidiBrackets.txt" "${UCD_SOURCE}/BidiTest.txt")

add_executable(unicode_contracts EXCLUDE_FROM_ALL
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_mirror_lookup_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_mirror_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_bracket_lookup_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_bracket_source_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_contracts_dats.c")
target_compile_definitions(unicode_contracts PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(unicode_contracts m)
add_test(NAME unicode_contracts COMMAND unicode_contracts "${UCD_SOURCE}/BidiMirroring.txt")
find_program(ANTHRACITE_PATSOPT patsopt REQUIRED)
add_test(NAME unicode_domain_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_domain_type_error.cmake")
