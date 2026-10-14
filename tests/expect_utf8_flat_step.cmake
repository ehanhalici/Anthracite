foreach(MODULE utf8_step utf8_window)
execute_process(COMMAND "${PATSOPT}" -IATS "${SOURCE_DIR}/src"
  -d "${SOURCE_DIR}/src/data_text/${MODULE}.dats"
  RESULT_VARIABLE RESULT OUTPUT_VARIABLE GENERATED ERROR_VARIABLE ERROR)
if(NOT RESULT EQUAL 0)
  message(FATAL_ERROR "UTF-8 ${MODULE} generation failed: ${ERROR}")
endif()
if(NOT GENERATED MATCHES "ATSINSmove_fltrec_beg")
  message(FATAL_ERROR "UTF-8 ${MODULE} is no longer a flat result")
endif()
if(GENERATED MATCHES "ATSINSmove_con[12]|ATSINSmove_boxrec|ATS_MALLOC")
  message(FATAL_ERROR "UTF-8 ${MODULE} introduced payload/boxed allocations")
endif()
endforeach()
