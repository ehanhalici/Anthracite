file(GLOB_RECURSE SINGLE_LOOKUP_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_single_lookup_*.dats")
set(SINGLE_LOOKUP_C_SOURCES "")
foreach(SOURCE ${SINGLE_LOOKUP_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND SINGLE_LOOKUP_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
add_test(NAME ot_single_lookup_type_error COMMAND "${CMAKE_COMMAND}"
  "-DPATSOPT=${ANTHRACITE_OT_PATSOPT}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_ot_single_lookup_error.cmake")
