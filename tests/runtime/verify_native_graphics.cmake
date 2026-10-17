string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef suffix)
set(fixture "${BINARY_DIR}/native-graphics-fixture-${suffix}")
file(MAKE_DIRECTORY "${fixture}")
execute_process(COMMAND "${EXECUTABLE}" "${fixture}/outline.ttf" "${fixture}/invalid.ttf"
    "${LATIN_FONT}" "${SOURCE_DIR}/vendor/fonts/notonaskh-arabic/NotoNaskhArabic-Regular.ttf"
    "${BINARY_DIR}" "${UNICODE_SOURCE}"
  WORKING_DIRECTORY "${SOURCE_DIR}" RESULT_VARIABLE result
  OUTPUT_VARIABLE output ERROR_VARIABLE diagnostics TIMEOUT 100)
file(REMOVE "${fixture}/outline.ttf" "${fixture}/invalid.ttf")
file(REMOVE_RECURSE "${fixture}")
if(NOT result EQUAL 0)
  message(FATAL_ERROR "Native graphic contracts failed (${result}): ${output}\n${diagnostics}")
endif()
message(STATUS "Verified native shaping, wrapping, clips, embed cache and selection: ${output}")
