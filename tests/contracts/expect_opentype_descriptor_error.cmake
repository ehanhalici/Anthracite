include("${SOURCE_DIR}/cmake/ATSSourceIndex.cmake")
execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/tests/font/opentype/tables/opentype_wrong_descriptor.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
if(RESULT EQUAL 0)
  message(FATAL_ERROR "Incompatible OpenType descriptors were accepted")
endif()
if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "OtDeviceRead" OR NOT ERROR MATCHES "maximum")
  message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
endif()
