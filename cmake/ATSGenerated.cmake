# Shared ATS outputs have one producer. All executable consumers wait for it;
# otherwise Make can run the same patsopt command in two target graphs at once.
get_property(ANTHRACITE_BUILD_TARGETS DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
foreach(TARGET IN LISTS ANTHRACITE_BUILD_TARGETS)
  get_target_property(TARGET_TYPE "${TARGET}" TYPE)
  if(TARGET_TYPE STREQUAL "EXECUTABLE")
    add_dependencies("${TARGET}" ats_generated)
  endif()
endforeach()
