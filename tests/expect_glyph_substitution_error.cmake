foreach(SOURCE glyph_substitution_wrong_prefix glyph_substitution_wrong_phase glyph_substitution_wrong_domain)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src" -d "${SOURCE_DIR}/tests/${SOURCE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0 OR NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected substitution type-state result for ${SOURCE}: ${ERROR}")
  endif()
endforeach()
