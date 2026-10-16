execute_process(COMMAND bash -c "ulimit -c 0; exec \"$1\" \"$2\""
    recursion-test "${EXECUTABLE}" "${MODE}"
  RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE diagnostic TIMEOUT 5)
if(NOT "${result}" STREQUAL "Subprocess aborted" AND NOT "${result}" STREQUAL "134")
  message(FATAL_ERROR "Expected recursion abort, got ${result}: ${output}\n${diagnostic}")
endif()
if(NOT diagnostic MATCHES "event=recursion_fuel status=failed")
  message(FATAL_ERROR "Missing explicit recursion exhaustion diagnostic: ${diagnostic}")
endif()
