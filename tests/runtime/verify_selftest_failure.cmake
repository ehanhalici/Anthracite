# Real production binary, no mocked selftest or test-only production switches.
# A regular file in place of the configuration directory makes the application
# selftest fail while the pinned native startup assets stay available.
string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef suffix)
set(fixture "${BINARY_DIR}/failed-selftest-${suffix}")
file(MAKE_DIRECTORY "${fixture}/empty")
file(WRITE "${fixture}/config" "not a directory\n")
execute_process(COMMAND "${CMAKE_COMMAND}" -E env
    "ANTHRACITE_CONFIG_DIR=${fixture}/config" "${EXECUTABLE}" --selftest
  WORKING_DIRECTORY "${fixture}/empty" RESULT_VARIABLE result
  OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics TIMEOUT 60)
if(NOT "${result}" STREQUAL "1")
  message(FATAL_ERROR "Failed core selftest must exit 1, got ${result}: ${output}\n${diagnostics}")
endif()
if(NOT output MATCHES "(^|\n)app_selftest=0([ \n]|$)")
  message(FATAL_ERROR "Fixture did not fail the application selftest: ${output}\n${diagnostics}")
endif()
if(NOT output MATCHES "(^|\n)font_selftest=1([ \n]|$)")
  message(FATAL_ERROR "Embedded fonts must pass the font selftest from any directory: ${output}\n${diagnostics}")
endif()
if(NOT "${output}\n${diagnostics}" MATCHES "event=selftest status=failed")
  message(FATAL_ERROR "Missing aggregate selftest failure: ${output}\n${diagnostics}")
endif()
if(NOT output MATCHES "memory_ok=1([ \n]|$)")
  message(FATAL_ERROR "Failed selftest did not restore tracked memory: ${output}\n${diagnostics}")
endif()
if("${output}\n${diagnostics}" MATCHES "event=display_error")
  message(FATAL_ERROR "Expected a running display, not a display initialization failure")
endif()
message(STATUS "A real failed core selftest exits 1 after cleanup")
