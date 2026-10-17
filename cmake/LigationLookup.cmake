file(GLOB_RECURSE LIGATION_LOOKUP_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_ligation_lookup_*.dats")
set(LIGATION_LOOKUP_C_SOURCES "")
foreach(SOURCE ${LIGATION_LOOKUP_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND LIGATION_LOOKUP_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
add_test(NAME glyph_ligation_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_glyph_ligation_error.cmake")
