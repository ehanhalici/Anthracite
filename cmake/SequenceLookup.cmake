file(GLOB SEQUENCE_LOOKUP_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_sequence_lookup_*.dats")
set(SEQUENCE_LOOKUP_C_SOURCES "")
foreach(SOURCE ${SEQUENCE_LOOKUP_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND SEQUENCE_LOOKUP_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
add_test(NAME glyph_sequence_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/expect_glyph_sequence_error.cmake")
