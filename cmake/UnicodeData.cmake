set(UCD_COMPILER_C "${CMAKE_CURRENT_BINARY_DIR}/unicode_compile_dats.c")
add_custom_command(OUTPUT ${UCD_COMPILER_C}
  COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -o ${UCD_COMPILER_C}
    -d ${CMAKE_CURRENT_SOURCE_DIR}/tools/unicode_compile.dats
  DEPENDS tools/unicode_compile.dats ${ATS_INTERFACES})
add_executable(unicode_compile EXCLUDE_FROM_ALL ${UCD_COMPILER_C}
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(unicode_compile PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(unicode_compile m)
set(UCD_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/vendor/unicode/18.0.0")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin"
  COMMAND unicode_compile "${UCD_SOURCE}/auxiliary/GraphemeBreakProperty.txt"
    "${UCD_SOURCE}/DerivedCoreProperties.txt" "${UCD_SOURCE}/emoji/emoji-data.txt"
    "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin"
  DEPENDS unicode_compile "${UCD_SOURCE}/auxiliary/GraphemeBreakProperty.txt"
    "${UCD_SOURCE}/DerivedCoreProperties.txt" "${UCD_SOURCE}/emoji/emoji-data.txt")
add_custom_target(unicode_data DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/unicode18.bin")

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/property_compile_dats.c"
  COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
    -o "${CMAKE_CURRENT_BINARY_DIR}/property_compile_dats.c" -d tools/property_compile.dats
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS tools/property_compile.dats ${ATS_INTERFACES})
add_executable(property_compile EXCLUDE_FROM_ALL "${CMAKE_CURRENT_BINARY_DIR}/property_compile_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/unicode_property_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/property_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/property_writer_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/line_property_symbols_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/category_property_symbols_dats.c")
target_compile_definitions(property_compile PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(property_compile m)
set(UNICODE_PROPERTY_OUTPUTS "")
foreach(DOMAIN word bidi joining line east-asian category ignorable modifier-mark)
  if(DOMAIN STREQUAL "word")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/auxiliary/WordBreakProperty.txt")
  elseif(DOMAIN STREQUAL "bidi")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/extracted/DerivedBidiClass.txt")
  elseif(DOMAIN STREQUAL "joining")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/extracted/DerivedJoiningType.txt")
  elseif(DOMAIN STREQUAL "line")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/LineBreak.txt")
  elseif(DOMAIN STREQUAL "east-asian")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/EastAsianWidth.txt")
  elseif(DOMAIN STREQUAL "ignorable")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/DerivedCoreProperties.txt")
  elseif(DOMAIN STREQUAL "modifier-mark")
    set(PROPERTY_SOURCE "${UCD_SOURCE}/PropList.txt")
  else()
    set(PROPERTY_SOURCE "${UCD_SOURCE}/extracted/DerivedGeneralCategory.txt")
  endif()
  set(PROPERTY_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/unicode18-${DOMAIN}.bin")
  add_custom_command(OUTPUT "${PROPERTY_OUTPUT}"
    COMMAND property_compile ${DOMAIN} "${PROPERTY_SOURCE}" "${PROPERTY_OUTPUT}"
    DEPENDS property_compile "${PROPERTY_SOURCE}")
  list(APPEND UNICODE_PROPERTY_OUTPUTS "${PROPERTY_OUTPUT}")
endforeach()
add_custom_target(unicode_properties DEPENDS ${UNICODE_PROPERTY_OUTPUTS})
