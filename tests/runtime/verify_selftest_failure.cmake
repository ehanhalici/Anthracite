# Real production binary, no mocked selftest or test-only production switches.
# font_selftest explicitly loads relative fonts. An empty working directory
# makes that check fail while the pinned native startup assets stay available.
string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef suffix)
set(fixture "${BINARY_DIR}/failed-selftest-${suffix}")
file(MAKE_DIRECTORY "${fixture}/empty" "${fixture}/config")
execute_process(COMMAND "${CMAKE_COMMAND}" -E env
    "ANTHRACITE_CONFIG_DIR=${fixture}/config" "${EXECUTABLE}" --selftest
  WORKING_DIRECTORY "${fixture}/empty" RESULT_VARIABLE result
  OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics TIMEOUT 60)
if(NOT "${result}" STREQUAL "1")
  message(FATAL_ERROR "Failed core selftest must exit 1, got ${result}: ${output}\n${diagnostics}")
endif()
if(NOT output MATCHES "(^|\n)font_selftest=0([ \n]|$)")
  message(FATAL_ERROR "Fixture did not fail the font selftest: ${output}\n${diagnostics}")
endif()
if(NOT "${output}\n${diagnostics}" MATCHES "event=selftest status=failed")
  message(FATAL_ERROR "Missing aggregate selftest failure: ${output}\n${diagnostics}")
endif()
if("${output}\n${diagnostics}" MATCHES "event=display_error")
  message(FATAL_ERROR "Expected a running display, not a display initialization failure")
endif()
message(STATUS "A real failed core selftest exits 1 after cleanup")
