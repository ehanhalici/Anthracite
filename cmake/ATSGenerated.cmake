# Shared ATS outputs have one producer. All executable consumers wait for it;
# otherwise Make can run the same patsopt command in two target graphs at once.
# The SIGPROF sampler is a developer tool: never in Release unless asked for.
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  option(ANTHRACITE_PROFILER "Compile the SIGPROF sampler (ANTHRACITE_PERF_PROFILE)" OFF)
else()
  option(ANTHRACITE_PROFILER "Compile the SIGPROF sampler (ANTHRACITE_PERF_PROFILE)" ON)
endif()
set(ANTHRACITE_PROFILER_SOURCES "")
if(ANTHRACITE_PROFILER)
  set(ANTHRACITE_PROFILER_SOURCES "${CMAKE_SOURCE_DIR}/src/core_runtime/perf_sampler.c")
  add_compile_definitions(ANTHRACITE_PROFILER)
endif()
set(ATS_KERNEL_C_SOURCES "")
foreach(ATS_FILE IN LISTS ATS_KERNEL_SOURCES)
  get_filename_component(BASE_NAME "${ATS_FILE}" NAME_WE)
  set(C_OUT "${CMAKE_CURRENT_BINARY_DIR}/kernel_${BASE_NAME}_dats.c")
  anthracite_ats_compile("${C_OUT}" "${ATS_FILE}"
    TYPECHECK
    INCLUDES "${CMAKE_SOURCE_DIR}/src" "$ENV{PATSHOME}" "$ENV{PATSHOME}/share"
    COMMENT "[ATS kernel] ${ATS_FILE}")
  list(APPEND ATS_KERNEL_C_SOURCES "${C_OUT}")
endforeach()
add_library(performance_counters OBJECT
  ${ATS_KERNEL_C_SOURCES}
  ${ANTHRACITE_PROFILER_SOURCES}
  )
target_include_directories(performance_counters PRIVATE "${CMAKE_SOURCE_DIR}/src")
target_compile_options(performance_counters PRIVATE -pthread)
target_compile_definitions(performance_counters PRIVATE ATS_MEMALLOC_USER _GNU_SOURCE)
set_target_properties(performance_counters PROPERTIES C_STANDARD 11)
# Every ATS allocation goes through the ATS2 arena (core_runtime/kernel/arena.dats),
# in the app and in all tests, so the whole suite exercises the allocator.
option(ANTHRACITE_ARENA "Route ATS allocations through the arena allocator" ON)
get_property(ANTHRACITE_BUILD_TARGETS DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
set(ANTHRACITE_TEST_OUTPUTS "")
set(ANTHRACITE_SHARED_TEST_OUTPUTS "")
foreach(TARGET IN LISTS ANTHRACITE_BUILD_TARGETS)
  get_target_property(TARGET_TYPE "${TARGET}" TYPE)
  # Object libraries (anthracite_host, native_text_engine) are linked into the
  # executables, so they must use the same allocator.
  if(ANTHRACITE_ARENA AND (TARGET_TYPE STREQUAL "OBJECT_LIBRARY" OR TARGET_TYPE STREQUAL "EXECUTABLE"))
    get_target_property(definitions "${TARGET}" COMPILE_DEFINITIONS)
    if(definitions)
      list(TRANSFORM definitions REPLACE "^ATS_MEMALLOC_LIBC$" "ATS_MEMALLOC_USER")
      set_target_properties("${TARGET}" PROPERTIES COMPILE_DEFINITIONS "${definitions}")
    endif()
  endif()
  if(TARGET_TYPE STREQUAL "EXECUTABLE")
    target_sources("${TARGET}" PRIVATE $<TARGET_OBJECTS:performance_counters>)
    target_compile_options("${TARGET}" PRIVATE -pthread)
    target_link_options("${TARGET}" PRIVATE -pthread)
    add_dependencies("${TARGET}" performance_counters)
    add_dependencies("${TARGET}" ats_generated)
    get_target_property(sources "${TARGET}" SOURCES)
    foreach(source IN LISTS sources)
      if(source MATCHES "_dats[.]c$" AND NOT source IN_LIST GENERATED_C_SOURCES)
        if(source IN_LIST ANTHRACITE_TEST_OUTPUTS)
          list(APPEND ANTHRACITE_SHARED_TEST_OUTPUTS "${source}")
        else()
          list(APPEND ANTHRACITE_TEST_OUTPUTS "${source}")
        endif()
      endif()
    endforeach()
  endif()
endforeach()

# The same race applies to shared test fixtures: each consumer otherwise gets
# its own Make rule and can truncate the C file while another target compiles it.
list(REMOVE_DUPLICATES ANTHRACITE_SHARED_TEST_OUTPUTS)
add_custom_target(ats_shared_test_generated DEPENDS ${ANTHRACITE_SHARED_TEST_OUTPUTS})
add_dependencies(ats_shared_test_generated ats_generated)
foreach(TARGET IN LISTS ANTHRACITE_BUILD_TARGETS)
  get_target_property(kind "${TARGET}" TYPE)
  if(kind STREQUAL "EXECUTABLE")
    get_target_property(sources "${TARGET}" SOURCES)
    foreach(source IN LISTS sources)
      if(source IN_LIST ANTHRACITE_SHARED_TEST_OUTPUTS)
        add_dependencies("${TARGET}" ats_shared_test_generated)
        break()
      endif()
    endforeach()
  endif()
endforeach()
