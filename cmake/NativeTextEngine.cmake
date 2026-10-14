# Reusable production CPU engine. No test fixtures, test entry points,
# Font ownership, GUI event loops, GPU state or legacy Arabic C renderer.
file(GLOB NATIVE_TEXT_PIPELINE_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/src/data_font/native_text_context_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/native_text_shape_*.dats"
  "${CMAKE_SOURCE_DIR}/src/data_font/native_text_coverage.dats")
set(NATIVE_TEXT_PIPELINE_C_SOURCES "")
foreach(SOURCE ${NATIVE_TEXT_PIPELINE_SOURCES})
  get_filename_component(MODULE "${SOURCE}" NAME_WE)
  list(APPEND NATIVE_TEXT_PIPELINE_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
set(NATIVE_TEXT_KERNEL_C_SOURCES
  ${NATIVE_TEXT_PIPELINE_C_SOURCES} ${NATIVE_TEXT_ANALYSIS_C_SOURCES} ${NATIVE_TEXT_ASSETS_C_SOURCES}
  ${GLYPH_POSITION_C_SOURCES} ${POSITION_LOOKUP_C_SOURCES} ${GLYPH_RUN_C_SOURCES} ${GLYPH_METADATA_C_SOURCES}
  ${GLYPH_NOMINAL_C_SOURCES} ${GLYPH_PASS_C_SOURCES} ${ARABIC_JOIN_C_SOURCES} ${ARABIC_MARKS_C_SOURCES}
  ${GPOS_SINGLE_C_SOURCES} ${GPOS_PAIR_C_SOURCES} ${GPOS_CURSIVE_C_SOURCES}
  ${GPOS_MARK_MATRIX_C_SOURCES} ${GPOS_MARK_LIGATURE_C_SOURCES} ${GPOS_MARK_SHARED_C_SOURCES} ${GPOS_VALUE_C_SOURCES}
  ${GSUB_SINGLE_C_SOURCES} ${SINGLE_LOOKUP_C_SOURCES} ${GSUB_SEQUENCE_C_SOURCES} ${SEQUENCE_LOOKUP_C_SOURCES}
  ${GSUB_LIGATURE_C_SOURCES} ${LIGATION_LOOKUP_C_SOURCES} ${GSUB_REVERSE_C_SOURCES} ${REVERSE_LOOKUP_C_SOURCES}
  ${SUBSTITUTION_GRAPH_C_SOURCES} ${OT_C_SOURCES} ${OT_LAYOUT_C_SOURCES} ${OT_CONTEXT_C_SOURCES} ${OT_COV_CACHE_C_SOURCES}
  ${NORMALIZATION_C_SOURCES} ${SCRIPT_C_SOURCES} ${SCRIPT_ITEMS_C_SOURCES} ${BIDI_C_SOURCES} ${LINE_ENGINE_C_SOURCES} ${UTF8_C_SOURCES})
foreach(MODULE sfnt glyph_pass_selection glyph_neighbor glyph_neighbor_checks glyph_neighbor_search
    unicode_sort unicode_db unicode_property grapheme mem fs_buf text_source text_fields
    font_run_measure font_run_geometry)
  list(APPEND NATIVE_TEXT_KERNEL_C_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${MODULE}_dats.c")
endforeach()
list(REMOVE_DUPLICATES NATIVE_TEXT_KERNEL_C_SOURCES)
add_library(native_text_engine OBJECT EXCLUDE_FROM_ALL ${NATIVE_TEXT_KERNEL_C_SOURCES})
target_compile_definitions(native_text_engine PRIVATE ATS_MEMALLOC_LIBC)
target_link_libraries(native_text_engine PUBLIC m)
add_dependencies(native_text_engine ats_generated)
# Production and conformance share the same compiled engine objects.
# Keep host/UI/legacy rendering sources in the application target.
get_target_property(NATIVE_TEXT_HOST_SOURCES anthracite SOURCES)
list(REMOVE_ITEM NATIVE_TEXT_HOST_SOURCES ${NATIVE_TEXT_KERNEL_C_SOURCES})
set_property(TARGET anthracite PROPERTY SOURCES "${NATIVE_TEXT_HOST_SOURCES}")
target_link_libraries(anthracite native_text_engine)
