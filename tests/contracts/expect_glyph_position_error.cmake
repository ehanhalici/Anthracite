include("${SOURCE_DIR}/cmake/ATSSourceIndex.cmake")
foreach(SOURCE glyph_position_wrong_phase glyph_position_double_finish glyph_position_lookup_wrong_prefix
  glyph_position_lookup_wrong_phase font_run_wrong_phase glyph_position_context_wrong_prefix glyph_position_context_wrong_phase)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src" -d "${ANTHRACITE_TEST_${SOURCE}}"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0 OR NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected positioned phase result for ${SOURCE}: ${ERROR}")
  endif()
endforeach()
