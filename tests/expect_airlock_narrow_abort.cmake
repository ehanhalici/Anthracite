foreach(ARGUMENT --narrow-overflow --narrow-underflow)
  execute_process(COMMAND bash -c "ulimit -c 0; exec \"$1\" \"$2\"" airlock-test "${EXECUTABLE}" "${ARGUMENT}"
    RESULT_VARIABLE STATUS ERROR_VARIABLE DIAGNOSTIC TIMEOUT 5)
  if("${STATUS}" STREQUAL "0" OR NOT DIAGNOSTIC MATCHES "event=airlock_i32 status=failed")
    message(FATAL_ERROR "The narrow numeric boundary accepted ${ARGUMENT}: ${STATUS}; ${DIAGNOSTIC}")
  endif()
endforeach()
