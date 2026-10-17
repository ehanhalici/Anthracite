string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef suffix)
set(config "${BINARY_DIR}/selftest-config-${suffix}")
file(MAKE_DIRECTORY "${config}")
execute_process(COMMAND "${CMAKE_COMMAND}" -E env "ANTHRACITE_CONFIG_DIR=${config}"
    "${EXECUTABLE}" --selftest
  WORKING_DIRECTORY "${SOURCE_DIR}" RESULT_VARIABLE result
  OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics TIMEOUT 60)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "Graphical selftest failed (${result}): ${output}\n${diagnostics}")
endif()
foreach(expected font_selftest=1 doc_selftest=1 img_selftest=1 app_selftest=1
    clip=1 poll_ok=1 rss_ok=1 memory_ok=1)
  if(NOT output MATCHES "${expected}([ \n]|$)")
    message(FATAL_ERROR "Missing successful ${expected}: ${output}\n${diagnostics}")
  endif()
endforeach()
if(output MATCHES "status=failed" OR diagnostics MATCHES "status=failed")
  message(FATAL_ERROR "Selftest emitted a failure: ${output}\n${diagnostics}")
endif()
message(STATUS "Verified graphical selftest: ${output}")
