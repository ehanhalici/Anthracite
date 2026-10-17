set(search_case_data "${CMAKE_CURRENT_BINARY_DIR}/search-case-map.bin")
add_custom_command(OUTPUT "${search_case_data}"
  COMMAND python3 "${CMAKE_SOURCE_DIR}/tools/search/compile_case_map.py"
    "${UCD_SOURCE}/UnicodeData.txt" "${search_case_data}"
  DEPENDS "${CMAKE_SOURCE_DIR}/tools/search/compile_case_map.py" "${UCD_SOURCE}/UnicodeData.txt")
add_custom_target(search_case_data DEPENDS "${search_case_data}")
add_dependencies(anthracite_host search_case_data)
anthracite_contract_test(search_performance tests/performance/search_performance.dats)
target_link_libraries(search_performance PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_dependencies(search_performance search_case_data)
anthracite_contract_test(literal_search_contracts tests/search/literal_search_contracts.dats)
target_link_libraries(literal_search_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_dependencies(literal_search_contracts search_case_data)
add_test(NAME literal_search_contracts COMMAND literal_search_contracts "${search_case_data}")
add_test(NAME search_case_map_compiler_contracts COMMAND python3 "${CMAKE_SOURCE_DIR}/tests/search/test_compile_case_map.py")
foreach(test search_geometry_contracts search_results_contracts)
  anthracite_contract_test(${test} "tests/search/${test}.dats")
  target_link_libraries(${test} PRIVATE anthracite_host native_text_engine ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
  add_dependencies(${test} search_case_data)
  add_test(NAME ${test} COMMAND ${test} "${search_case_data}")
endforeach()
