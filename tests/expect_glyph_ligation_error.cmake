foreach(SOURCE glyph_ligation_wrong_prefix glyph_ligation_wrong_phase glyph_ligation_nominal_phase)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src" -d "${SOURCE_DIR}/tests/${SOURCE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0 OR NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected ligation type-state result for ${SOURCE}: ${ERROR}")
  endif()
endforeach()
