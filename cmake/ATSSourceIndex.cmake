# Source identities are stable basenames; source locations may be nested.
# The same index is used by configuration and cmake -P rejection tests.
get_filename_component(ANTHRACITE_SOURCE_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)

function(anthracite_index_sources directory namespace)
  if(CMAKE_SCRIPT_MODE_FILE)
    file(GLOB_RECURSE sources "${directory}/*.dats")
  else()
    file(GLOB_RECURSE sources CONFIGURE_DEPENDS "${directory}/*.dats")
  endif()
  foreach(source IN LISTS sources)
    get_filename_component(module "${source}" NAME_WE)
    if(DEFINED ${namespace}_${module})
      message(FATAL_ERROR "Duplicate ATS module ${module} in ${directory}")
    endif()
    set(${namespace}_${module} "${source}")
    set(${namespace}_${module} "${source}" PARENT_SCOPE)
  endforeach()
endfunction()

anthracite_index_sources("${ANTHRACITE_SOURCE_ROOT}/src" ANTHRACITE_SOURCE)
anthracite_index_sources("${ANTHRACITE_SOURCE_ROOT}/tests" ANTHRACITE_TEST)
anthracite_index_sources("${ANTHRACITE_SOURCE_ROOT}/tools" ANTHRACITE_TOOL)
