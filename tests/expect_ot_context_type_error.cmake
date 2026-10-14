execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/tests/ot_context_wrong_domain.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
if(RESULT EQUAL 0)
  message(FATAL_ERROR "A GPOS context action was accepted as a GSUB action")
endif()
if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "S2Eeqeq\\(S2Eintinf\\(2\\); S2Eintinf\\(1\\)\\)")
  message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
endif()
