foreach(SOURCE glyph_run_wrong_phase glyph_pass_wrong_phase)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
    -d "${SOURCE_DIR}/tests/${SOURCE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0)
    message(FATAL_ERROR "A frozen glyph run accepted a substitution: ${SOURCE}")
  endif()
  if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
  endif()
endforeach()
