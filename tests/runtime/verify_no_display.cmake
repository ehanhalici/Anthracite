# This negative process test runs on headless CI, independently of graphics.
string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef suffix)
set(config "${BINARY_DIR}/no-display-config-${suffix}")
file(MAKE_DIRECTORY "${config}")
foreach(mode application selftest)
  set(arguments "")
  if(mode STREQUAL "selftest")
    set(arguments --selftest)
  endif()
  execute_process(COMMAND "${CMAKE_COMMAND}" -E env "DISPLAY="
      "ANTHRACITE_CONFIG_DIR=${config}" "${EXECUTABLE}" ${arguments}
    WORKING_DIRECTORY "${SOURCE_DIR}" RESULT_VARIABLE result
    OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics TIMEOUT 10)
  if(NOT "${result}" STREQUAL "1")
    message(FATAL_ERROR "No-display ${mode} must exit 1, got ${result}: ${output}\n${diagnostics}")
  endif()
  if(NOT "${output}\n${diagnostics}" MATCHES "event=display_error status=failed error=cannot_open_display")
    message(FATAL_ERROR "Missing display_error for ${mode}: ${output}\n${diagnostics}")
  endif()
endforeach()
message(STATUS "Application and selftest both exit 1 without a display")
