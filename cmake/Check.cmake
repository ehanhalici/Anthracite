# CTest does not build EXCLUDE_FROM_ALL executables. Make the verification
# entry point explicitly build every executable before starting the tests.
get_property(ANTHRACITE_CHECK_TARGETS DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
add_custom_target(check-build)
foreach(target IN LISTS ANTHRACITE_CHECK_TARGETS)
  get_target_property(kind "${target}" TYPE)
  if(kind STREQUAL "EXECUTABLE")
    add_dependencies(check-build "${target}")
  endif()
endforeach()
add_custom_target(check
  COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  DEPENDS check-build
  USES_TERMINAL)
