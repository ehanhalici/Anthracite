file(GLOB_RECURSE GLYPH_NOMINAL_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/glyph_nominal*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/glyph_unicode_*.dats")
set(GLYPH_NOMINAL_C_SOURCES "")
foreach(SOURCE ${GLYPH_NOMINAL_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND GLYPH_NOMINAL_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
