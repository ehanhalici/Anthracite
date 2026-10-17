function(anthracite_contract_test name source)
  set(generated "${CMAKE_CURRENT_BINARY_DIR}/${name}_dats.c")
  add_custom_command(OUTPUT "${generated}"
    COMMAND patsopt -tc -IATS "${CMAKE_SOURCE_DIR}/src" -d "${CMAKE_SOURCE_DIR}/${source}"
    COMMAND patsopt -IATS "${CMAKE_SOURCE_DIR}/src" -o "${generated}" -d "${CMAKE_SOURCE_DIR}/${source}"
    DEPENDS "${source}" ${ATS_INTERFACES})
  add_executable(${name} EXCLUDE_FROM_ALL "${generated}" ${ARGN})
  target_compile_definitions(${name} PRIVATE ATS_MEMALLOC_LIBC)
  target_link_libraries(${name} PRIVATE m)
endfunction()

anthracite_contract_test(document_performance tests/performance/document_performance.dats)
target_link_libraries(document_performance PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_executable(performance_counter_contracts EXCLUDE_FROM_ALL tests/performance/performance_counter_contracts.c)
add_test(NAME performance_counter_contracts COMMAND performance_counter_contracts)
add_test(NAME performance_summary_contracts COMMAND python3 "${CMAKE_SOURCE_DIR}/tests/performance/test_summarize.py")
anthracite_contract_test(fold_scaling_contracts tests/performance/fold_scaling_contracts.dats)
target_link_libraries(fold_scaling_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME fold_scaling_contracts COMMAND fold_scaling_contracts)
anthracite_contract_test(anchor_contracts tests/workspace/anchor_contracts.dats)
target_link_libraries(anchor_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME anchor_contracts COMMAND anchor_contracts)

anthracite_contract_test(selftest_memory_contracts tests/runtime/selftest_memory_contracts.dats)
target_link_libraries(selftest_memory_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME selftest_memory_contracts COMMAND selftest_memory_contracts)

anthracite_contract_test(selftest_fixture_contracts tests/runtime/selftest_fixture_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c" "${CMAKE_CURRENT_BINARY_DIR}/fs_buf_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/selftest_fixture_dats.c")
add_test(NAME selftest_fixture_contracts COMMAND selftest_fixture_contracts)

foreach(mode missing configured)
  add_executable(unifont_${mode}_contracts EXCLUDE_FROM_ALL tests/runtime/unifont_path_contracts.c)
  target_link_libraries(unifont_${mode}_contracts PRIVATE ${OPENGL_LIBRARIES} m)
endforeach()
string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef unifont_suffix)
target_compile_definitions(unifont_missing_contracts PRIVATE
  "ANTHRACITE_UNIFONT=\"${CMAKE_CURRENT_BINARY_DIR}/absent-unifont-${unifont_suffix}/unifont.bin\"")
target_compile_definitions(unifont_configured_contracts PRIVATE
  "ANTHRACITE_UNIFONT=\"${CMAKE_SOURCE_DIR}/src/data_font/unifont.bin\"")
foreach(mode missing configured source_relative parent_relative)
  set(executable unifont_missing_contracts)
  set(expected 1)
  if(mode STREQUAL missing)
    set(expected 0)
  elseif(mode STREQUAL configured)
    set(executable unifont_configured_contracts)
  endif()
  add_test(NAME unifont_${mode}_path COMMAND "${CMAKE_COMMAND}"
    "-DEXECUTABLE=$<TARGET_FILE:${executable}>" "-DEXPECTED=${expected}"
    "-DBINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}" "-DLAYOUT=${mode}"
    -P "${CMAKE_SOURCE_DIR}/tests/runtime/verify_unifont_path.cmake")
endforeach()

anthracite_contract_test(recursion_fuel_contracts tests/runtime/recursion_fuel_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c")
add_test(NAME recursion_fuel_contracts COMMAND recursion_fuel_contracts)
foreach(mode fold query)
  add_test(NAME recursion_fuel_${mode}_exhausted COMMAND "${CMAKE_COMMAND}"
    "-DEXECUTABLE=$<TARGET_FILE:recursion_fuel_contracts>" "-DMODE=--${mode}"
    -P "${CMAKE_SOURCE_DIR}/tests/contracts/expect_recursion_abort.cmake")
endforeach()

anthracite_contract_test(core_contracts tests/memory/core_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/layout_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/ix_store_dats.c")
anthracite_contract_test(editor_fsm_contracts tests/workspace/editor_fsm_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c"
  "${CMAKE_CURRENT_BINARY_DIR}/editor_fsm_dats.c")
add_test(NAME core_contracts COMMAND core_contracts)
anthracite_contract_test(word_boundary_contracts tests/memory/word_boundary_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c")
target_compile_options(word_boundary_contracts PRIVATE -fno-wrapv -fsanitize=undefined -fno-sanitize-recover=undefined)
target_link_options(word_boundary_contracts PRIVATE -fsanitize=undefined)
add_test(NAME word_boundary_contracts COMMAND word_boundary_contracts)
add_executable(copy_boundary_contracts EXCLUDE_FROM_ALL tests/memory/copy_boundary_contracts.c)
target_compile_options(copy_boundary_contracts PRIVATE -fno-wrapv -fsanitize=undefined -fno-sanitize-recover=undefined)
target_link_options(copy_boundary_contracts PRIVATE -fsanitize=undefined)
add_test(NAME copy_boundary_contracts COMMAND copy_boundary_contracts)
add_test(NAME editor_fsm_contracts COMMAND editor_fsm_contracts)

anthracite_contract_test(event_repaint_contracts tests/runtime/event_repaint_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/event_repaint_dats.c")
target_link_libraries(event_repaint_contracts PRIVATE ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME event_repaint_contracts COMMAND event_repaint_contracts)

add_test(NAME graphics_selftest COMMAND "${CMAKE_COMMAND}"
  "-DEXECUTABLE=$<TARGET_FILE:anthracite>" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  "-DBINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}" -P "${CMAKE_SOURCE_DIR}/tests/runtime/verify_graphics.cmake")
set_tests_properties(graphics_selftest PROPERTIES LABELS graphics RUN_SERIAL TRUE TIMEOUT 90)
add_test(NAME selftest_no_display COMMAND "${CMAKE_COMMAND}"
  "-DEXECUTABLE=$<TARGET_FILE:anthracite>" "-DSOURCE_DIR=${CMAKE_SOURCE_DIR}"
  "-DBINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}" -P "${CMAKE_SOURCE_DIR}/tests/runtime/verify_no_display.cmake")
set_tests_properties(selftest_no_display PROPERTIES LABELS "runtime;negative" TIMEOUT 30)
add_test(NAME graphics_selftest_failure COMMAND "${CMAKE_COMMAND}"
  "-DEXECUTABLE=$<TARGET_FILE:anthracite>" "-DBINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}"
  -P "${CMAKE_SOURCE_DIR}/tests/runtime/verify_selftest_failure.cmake")
set_tests_properties(graphics_selftest_failure PROPERTIES LABELS "graphics;negative" RUN_SERIAL TRUE TIMEOUT 90)
add_test(NAME source_integrity COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_SOURCE_DIR}/cmake/SourceIntegrity.cmake")

anthracite_contract_test(fold_contracts tests/folds/fold_contracts.dats)
anthracite_contract_test(callout_contracts tests/folds/callout_contracts.dats)
target_link_libraries(callout_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME callout_contracts COMMAND callout_contracts)
anthracite_contract_test(region_sort_contracts tests/folds/region_sort_contracts.dats
  "${CMAKE_CURRENT_BINARY_DIR}/mem_dats.c")
add_test(NAME region_sort_contracts COMMAND region_sort_contracts)
target_link_libraries(fold_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
foreach(case paragraf_liste girintili_devam ic_ice_liste durum_koruma baslik_hiyerarsi
    kod_blok_icinde_diyez callout_alinti liste_ici_bos_satir tab_girinti
    alt_tik_derin_katlama ofset_kaymasi yaprak_madde)
  add_test(NAME fold_${case} COMMAND "${CMAKE_COMMAND}"
    "-DEXECUTABLE=$<TARGET_FILE:fold_contracts>"
    "-DFIXTURE=${CMAKE_SOURCE_DIR}/tests/folds/${case}.md"
    "-DGOLDEN=${CMAKE_SOURCE_DIR}/tests/folds/${case}.golden"
    -P "${CMAKE_SOURCE_DIR}/tests/folds/compare_golden.cmake")
endforeach()
set_tests_properties(fold_callout_alinti PROPERTIES LABELS fold)

anthracite_contract_test(workspace_contracts tests/workspace/workspace_contracts.dats)
target_link_libraries(workspace_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
foreach(mode image config document)
  add_test(NAME workspace_${mode}_contracts COMMAND "${CMAKE_COMMAND}"
    "-DEXECUTABLE=$<TARGET_FILE:workspace_contracts>" "-DMODE=${mode}"
    "-DBINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}" -P "${CMAKE_SOURCE_DIR}/tests/workspace/run_isolated.cmake")
endforeach()
set_tests_properties(workspace_document_contracts PROPERTIES LABELS document)

anthracite_contract_test(incremental_parser_contracts tests/workspace/incremental_parser_contracts.dats)
target_link_libraries(incremental_parser_contracts PRIVATE anthracite_host native_text_engine
  ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME incremental_parser_contracts COMMAND incremental_parser_contracts)
set_tests_properties(incremental_parser_contracts PROPERTIES LABELS document)

anthracite_contract_test(image_oracle_contracts tests/image/test_jpg_oracle.dats)
target_include_directories(image_oracle_contracts PRIVATE "${CMAKE_SOURCE_DIR}/vendor" "${CMAKE_SOURCE_DIR}" "${CMAKE_SOURCE_DIR}/tests")
target_link_libraries(image_oracle_contracts PRIVATE anthracite_host native_text_engine m ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
add_test(NAME image_oracle_contracts COMMAND image_oracle_contracts)
set_tests_properties(image_oracle_contracts PROPERTIES WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
set_tests_properties(image_oracle_contracts PROPERTIES LABELS "image;jpeg;oracle" TIMEOUT 30)
file(GLOB jpeg_fixtures CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/tests/fixtures/jpeg/*.jpg")
foreach(fixture IN LISTS jpeg_fixtures)
  get_filename_component(case "${fixture}" NAME_WE)
  add_test(NAME jpeg_${case} COMMAND image_oracle_contracts "${fixture}")
  set_tests_properties(jpeg_${case} PROPERTIES LABELS "image;jpeg;oracle" TIMEOUT 30)
endforeach()
file(GLOB jpeg_rejections CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/tests/fixtures/jpeg/reject/*.jpg")
foreach(fixture IN LISTS jpeg_rejections)
  get_filename_component(case "${fixture}" NAME_WE)
  add_test(NAME jpeg_reject_${case} COMMAND image_oracle_contracts reject "${fixture}")
  set_tests_properties(jpeg_reject_${case} PROPERTIES LABELS "image;jpeg;negative" TIMEOUT 30)
endforeach()
