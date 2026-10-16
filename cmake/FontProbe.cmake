add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/font_probe_dats.c"
  COMMAND patsopt -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
    -o "${CMAKE_CURRENT_BINARY_DIR}/font_probe_dats.c" -d tools/font/font_probe.dats
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS tools/font/font_probe.dats ${ATS_INTERFACES})
add_executable(font_probe EXCLUDE_FROM_ALL "${CMAKE_CURRENT_BINARY_DIR}/font_probe_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/sfnt_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/text_source_dats.c")
target_compile_definitions(font_probe PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(font_probe m)
