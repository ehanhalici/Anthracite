foreach(MODULE ot_layout_wrong_phase ot_layout_wrong_domain)
  if(MODULE STREQUAL "ot_layout_wrong_phase")
    set(INVALID_INDEX "S2Eintinf\\(0\\)")
  else()
    set(INVALID_INDEX "S2Eintinf\\(2\\)")
  endif()
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
    -d "${SOURCE_DIR}/tests/${MODULE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0)
    message(FATAL_ERROR "${MODULE} accepted incompatible OpenType types")
  endif()
  if(NOT ERROR MATCHES "error\\(3\\)" OR NOT ERROR MATCHES "unsolved constraint"
      OR NOT ERROR MATCHES "${INVALID_INDEX}" OR NOT ERROR MATCHES "S2Eintinf\\(1\\)")
    message(FATAL_ERROR "Unexpected compiler failure: ${ERROR}")
  endif()
endforeach()
