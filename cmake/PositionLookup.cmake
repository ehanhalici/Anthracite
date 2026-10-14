file(GLOB POSITION_LOOKUP_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/data_font/ot_position_lookup_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/ot_position_graph_*.dats")
set(POSITION_LOOKUP_C_SOURCES "")
foreach(SOURCE ${POSITION_LOOKUP_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND POSITION_LOOKUP_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
