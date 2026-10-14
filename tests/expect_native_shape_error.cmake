foreach(MODULE native_shape_wrong_source native_shape_wrong_schedule arabic_marks_wrong_data)
  execute_process(COMMAND "${PATSOPT}" -tc -IATS "${SOURCE_DIR}/src"
    -d "${SOURCE_DIR}/tests/${MODULE}.dats"
    RESULT_VARIABLE RESULT OUTPUT_VARIABLE OUTPUT ERROR_VARIABLE ERROR)
  if(RESULT EQUAL 0 OR NOT ERROR MATCHES "error\\(3\\)" OR
      NOT ERROR MATCHES "unsolved constraint|mismatch of static terms")
    message(FATAL_ERROR "Unexpected native shape contract result for ${MODULE}: ${ERROR}")
  endif()
endforeach()

