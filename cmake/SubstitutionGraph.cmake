file(GLOB_RECURSE SUBSTITUTION_GRAPH_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_substitution_graph_*.dats")
set(SUBSTITUTION_GRAPH_C_SOURCES "")
foreach(SOURCE ${SUBSTITUTION_GRAPH_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND SUBSTITUTION_GRAPH_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
add_test(NAME glyph_substitution_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_glyph_substitution_error.cmake")
