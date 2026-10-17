include("${SOURCE_DIR}/cmake/ATSSourceIndex.cmake")
foreach(SOURCE ot_single_lookup_wrong_prefix glyph_metadata_wrong_prefix)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
    -d "${ANTHRACITE_TEST_${SOURCE}}"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0)
    message(FATAL_ERROR "A partial native cache accepted a query: ${SOURCE}")
  endif()
  if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
    message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
  endif()
endforeach()
