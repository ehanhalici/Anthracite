set(TEXT_TEST_C "${CMAKE_CURRENT_BINARY_DIR}/text_conformance_dats.c")
add_custom_command(OUTPUT ${TEXT_TEST_C}
  COMMAND patsopt -tc -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
    -d ${CMAKE_CURRENT_SOURCE_DIR}/tests/text/grapheme/text_conformance.dats
  COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -o ${TEXT_TEST_C}
    -d ${CMAKE_CURRENT_SOURCE_DIR}/tests/text/grapheme/text_conformance.dats
  DEPENDS tests/text/grapheme/text_conformance.dats ${ATS_INTERFACES})
add_executable(text_conformance EXCLUDE_FROM_ALL ${TEXT_TEST_C}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" ${UTF8_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/grapheme_dats.c")
target_compile_definitions(text_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(text_conformance m)
add_dependencies(text_conformance unicode_data)
add_test(NAME text_conformance COMMAND text_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin" "${UCD_SOURCE}/auxiliary/GraphemeBreakTest.txt")

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/word_conformance_dats.c"
  COMMAND patsopt -tc -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -d tests/text/word_break/word_conformance.dats
  COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
    -o "${CMAKE_CURRENT_BINARY_DIR}/word_conformance_dats.c" -d tests/text/word_break/word_conformance.dats
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS tests/text/word_break/word_conformance.dats ${ATS_INTERFACES})
add_executable(word_conformance EXCLUDE_FROM_ALL "${CMAKE_CURRENT_BINARY_DIR}/word_conformance_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" ${UTF8_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_db_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/word_predicates_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/word_state_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/word_rules_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/word_segment_dats.c")
target_compile_definitions(word_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(word_conformance m)
add_dependencies(word_conformance unicode_data unicode_properties)
add_test(NAME word_conformance COMMAND word_conformance
  "${CMAKE_CURRENT_BINARY_DIR}/unicode18-word.bin" "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin"
  "${UCD_SOURCE}/auxiliary/WordBreakTest.txt")

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/bidi_core_conformance_dats.c"
  COMMAND patsopt -tc -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -d tests/text/bidi/bidi_core_conformance.dats
  COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
    -o "${CMAKE_CURRENT_BINARY_DIR}/bidi_core_conformance_dats.c" -d tests/text/bidi/bidi_core_conformance.dats
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS tests/text/bidi/bidi_core_conformance.dats ${ATS_INTERFACES})
add_executable(bidi_core_conformance EXCLUDE_FROM_ALL "${CMAKE_CURRENT_BINARY_DIR}/bidi_core_conformance_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" ${UTF8_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_class_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_buffer_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_isolates_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_paragraph_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_status_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_embedding_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/bidi_event_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/bidi_explicit_dats.c")
target_compile_definitions(bidi_core_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(bidi_core_conformance m)
add_dependencies(bidi_core_conformance unicode_properties)
add_test(NAME bidi_core_conformance COMMAND bidi_core_conformance "${CMAKE_CURRENT_BINARY_DIR}/unicode18-bidi.bin")
