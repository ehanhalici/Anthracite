execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/tests/gsub_single_wrong_descriptor.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
if(RESULT EQUAL 0)
  message(FATAL_ERROR "Unvalidated layout topology was accepted as a GSUB payload")
endif()
if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "GsubSingle" OR NOT ERROR MATCHES "OtLayoutTable")
  message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
endif()
