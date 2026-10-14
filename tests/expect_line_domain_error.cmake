execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/tests/line_wrong_domain.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
if(RESULT EQUAL 0)
  message(FATAL_ERROR "Word property map was accepted as a line property map")
endif()
if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "S2Eintinf\\(1\\).*S2Eintinf\\(4\\)")
  message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
endif()
