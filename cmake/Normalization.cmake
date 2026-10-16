# Native Unicode normalization data generation; no external text library.
set(NORMALIZATION_C_SOURCES "")
foreach(ATS_FILE IN LISTS ATS_SOURCES)
  if(ATS_FILE MATCHES "/normalization_[^/]+\\.dats$")
    get_filename_component(MODULE "${ATS_FILE}" NAME_WE)
    list(APPEND NORMALIZATION_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
  endif()
endforeach()
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/normalization_compile_dats.c"
  COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -d "${CMAKE_SOURCE_DIR}/tools/unicode/normalization_compile.dats"
  COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src"
    -o "${CMAKE_CURRENT_BINARY_DIR}/normalization_compile_dats.c" -d "${CMAKE_SOURCE_DIR}/tools/unicode/normalization_compile.dats"
  DEPENDS tools/unicode/normalization_compile.dats ${ATS_INTERFACES})
add_executable(normalization_compile EXCLUDE_FROM_ALL ${NORMALIZATION_C_SOURCES}
  "${CMAKE_CURRENT_BINARY_DIR}/normalization_compile_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_fields_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/unicode_sort_dats.c" ${UTF8_C_SOURCES})
target_compile_definitions(normalization_compile PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(normalization_compile m)
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin"
  COMMAND normalization_compile "${UCD_SOURCE}/UnicodeData.txt"
    "${UCD_SOURCE}/DerivedNormalizationProps.txt" "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin"
  DEPENDS normalization_compile "${UCD_SOURCE}/UnicodeData.txt" "${UCD_SOURCE}/DerivedNormalizationProps.txt")
add_custom_target(normalization_data DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/unicode18-normalization.bin")

include(cmake/NormalizationTests.cmake)
