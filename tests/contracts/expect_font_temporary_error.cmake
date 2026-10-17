foreach(kind TEXT_RESULT TEXT_ENABLE SFNT_TABLE SFNT_PARSED COMPONENT FEATURE_PARAMS)
  execute_process(COMMAND "${PATSOPT}" -tc -DATS "CHECK_${kind}"
    -IATS "${SOURCE_DIR}/src" -d "${SOURCE_DIR}/tests/contracts/font_temporary_leak.dats"
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics)
  if(result EQUAL 0 OR NOT diagnostics MATCHES "error\\(3\\)"
      OR NOT diagnostics MATCHES "needs to be consumed")
    message(FATAL_ERROR "Temporary ownership contract ${kind}: ${diagnostics}")
  endif()
endforeach()
