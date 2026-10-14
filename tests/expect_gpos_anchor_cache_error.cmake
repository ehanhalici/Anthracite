execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/tests/gpos_anchor_cache_unfinished.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
if(RESULT EQUAL 0)
  message(FATAL_ERROR "A partially initialized Anchor cache was queried")
endif()
if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint")
  message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
endif()
