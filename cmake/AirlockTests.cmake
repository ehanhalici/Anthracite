add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/airlock_conformance_dats.c"
  COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -d "${CMAKE_SOURCE_DIR}/tests/memory/airlock_conformance.dats"
  COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src"
    -o "${CMAKE_CURRENT_BINARY_DIR}/airlock_conformance_dats.c" -d "${CMAKE_SOURCE_DIR}/tests/memory/airlock_conformance.dats"
  DEPENDS tests/memory/airlock_conformance.dats ${ATS_INTERFACES})
add_executable(airlock_conformance EXCLUDE_FROM_ALL "${CMAKE_CURRENT_BINARY_DIR}/airlock_conformance_dats.c")
target_compile_definitions(airlock_conformance PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(airlock_conformance m)
add_test(NAME airlock_conformance COMMAND airlock_conformance)
add_test(NAME airlock_overflow COMMAND ${CMAKE_COMMAND}
  "-DEXECUTABLE=$<TARGET_FILE:airlock_conformance>" -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/contracts/expect_airlock_abort.cmake")
add_test(NAME airlock_narrow_overflow COMMAND ${CMAKE_COMMAND}
  "-DEXECUTABLE=$<TARGET_FILE:airlock_conformance>" -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/contracts/expect_airlock_narrow_abort.cmake")
