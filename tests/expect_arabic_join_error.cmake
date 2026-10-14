foreach(SOURCE glyph_arabic_wrong_phase arabic_join_wrong_domain)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
    -d "${SOURCE_DIR}/tests/${SOURCE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0)
    message(FATAL_ERROR "Joining accepted an invalid phase/property domain: ${SOURCE}")
  endif()
  if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
  endif()
endforeach()
