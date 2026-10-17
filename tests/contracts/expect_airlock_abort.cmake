if(NOT DEFINED EXECUTABLE)
  message(FATAL_ERROR "Missing airlock test executable")
endif()
execute_process(
  COMMAND bash -c "ulimit -c 0; exec \"$1\" --overflow" airlock-test "${EXECUTABLE}"
  RESULT_VARIABLE status ERROR_VARIABLE diagnostic OUTPUT_VARIABLE output TIMEOUT 5)
if("${status}" STREQUAL "0" OR NOT diagnostic MATCHES "event=airlock_span status=failed")
  message(FATAL_ERROR "Overflow airlock did not reject input: ${status}; ${diagnostic}")
endif()
