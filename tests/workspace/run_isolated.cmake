string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef suffix)
set(fixture "${BINARY_DIR}/workspace-${MODE}-${suffix}")
set(config "${fixture}/config")
file(MAKE_DIRECTORY "${config}")
execute_process(COMMAND "${CMAKE_COMMAND}" -E env "ANTHRACITE_CONFIG_DIR=${config}"
    "${EXECUTABLE}" "${MODE}" "${fixture}"
  RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics TIMEOUT 30)
if(NOT result EQUAL 0 OR NOT output MATCHES "event=workspace_contracts mode=${MODE} errors=0")
  message(FATAL_ERROR "Isolated ${MODE} contracts failed (${result}): ${output}\n${diagnostics}")
endif()
