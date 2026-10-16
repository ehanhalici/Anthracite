include("${SOURCE_DIR}/cmake/ATSSourceIndex.cmake")
execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/tests/text/normalization/normalization_wrong_phase.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
if(RESULT EQUAL 0)
  message(FATAL_ERROR "Unordered text was accepted by the composition API")
endif()
if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "S2Eintinf\\(0\\).*S2Eintinf\\(1\\)")
  message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
endif()
