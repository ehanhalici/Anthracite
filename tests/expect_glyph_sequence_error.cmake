foreach(SOURCE ot_sequence_lookup_wrong_prefix glyph_expansion_wrong_prefix glyph_sequence_wrong_kind glyph_sequence_wrong_phase)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
    -d "${SOURCE_DIR}/tests/${SOURCE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0)
    message(FATAL_ERROR "A partial cache or wrong GSUB kind/phase was accepted: ${SOURCE}")
  endif()
  if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
  endif()
endforeach()
