cmake_minimum_required(VERSION 3.16)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Debug veya Release" FORCE)
endif()

find_program(ANTHRACITE_CLANG clang REQUIRED)
set(CMAKE_C_COMPILER "${ANTHRACITE_CLANG}" CACHE FILEPATH "clang" FORCE)
set(CMAKE_EXE_LINKER_FLAGS "" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS "-I${CMAKE_SOURCE_DIR}/src -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE -Wno-implicit-function-declaration -U_FORTIFY_SOURCE" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_DEBUG "-O0 -g" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE "-O2 -flto=thin -march=native -funroll-loops -fomit-frame-pointer -fvectorize -fslp-vectorize -DNDEBUG" CACHE STRING "" FORCE)

project(anthracite C)

set(CMAKE_C_STANDARD 99)

set(PATSHOME $ENV{PATSHOME})
if("${PATSHOME}" STREQUAL "")
  message(FATAL_ERROR "HATA: PATSHOME ortam değişkeni bulunamadı. nix-shell içinde olduğunuzdan emin olun.")
endif()

include_directories("${PATSHOME}" "${PATSHOME}/ccomp/runtime")

add_definitions(-DGL_GLEXT_PROTOTYPES)

find_package(X11 REQUIRED)
include_directories(${X11_INCLUDE_DIR})

set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED)
if(OPENGL_gl_LIBRARY MATCHES "libOpenGL")
  get_filename_component(_gl_dir "${OPENGL_gl_LIBRARY}" DIRECTORY)
  if(EXISTS "${_gl_dir}/libGL.so")
    set(OPENGL_gl_LIBRARY "${_gl_dir}/libGL.so")
    set(OPENGL_LIBRARIES "${_gl_dir}/libGL.so")
  endif()
endif()

include_directories(${X11_INCLUDE_DIR} ${OPENGL_INCLUDE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/src)

file(GLOB_RECURSE ATS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.dats")
list(SORT ATS_SOURCES)
if(NOT ATS_SOURCES)
  message(FATAL_ERROR "src altında .dats bulunamadı")
endif()

set(GENERATED_C_SOURCES "")
set(SEEN_BASE "")

foreach(ATS_FILE ${ATS_SOURCES})
  get_filename_component(BASE_NAME ${ATS_FILE} NAME_WE)
  if(BASE_NAME IN_LIST SEEN_BASE)
    message(FATAL_ERROR "Aynı ada sahip iki .dats var, C çıktısı çakışır: ${BASE_NAME}")
  endif()
  list(APPEND SEEN_BASE ${BASE_NAME})

  set(C_OUT "${CMAKE_CURRENT_BINARY_DIR}/${BASE_NAME}_dats.c")
  add_custom_command(
    OUTPUT ${C_OUT}
    COMMAND patsopt --debug --debug2
      -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
      -IATS $ENV{PATSHOME}
      -IATS $ENV{PATSHOME}/share
      -o ${C_OUT}
      -d ${ATS_FILE}
    DEPENDS ${ATS_FILE}
    COMMENT "[ATS] ${ATS_FILE} -> ${BASE_NAME}_dats.c"
  )
  list(APPEND GENERATED_C_SOURCES ${C_OUT})
endforeach()

add_executable(anthracite ${GENERATED_C_SOURCES})
target_compile_definitions(anthracite PRIVATE ATS_MEMALLOC_LIBC "ANTHRACITE_UNIFONT=\"${CMAKE_SOURCE_DIR}/src/data_font/unifont.bin\"")

set(ANTHRACITE_RPATH_DIRS "")
foreach(lib IN LISTS X11_LIBRARIES OPENGL_LIBRARIES)
  if(IS_ABSOLUTE "${lib}")
    get_filename_component(libdir "${lib}" DIRECTORY)
    list(APPEND ANTHRACITE_RPATH_DIRS "${libdir}")
  endif()
endforeach()
list(REMOVE_DUPLICATES ANTHRACITE_RPATH_DIRS)
foreach(dir IN LISTS ANTHRACITE_RPATH_DIRS)
  target_link_options(anthracite PRIVATE "-Wl,-rpath,${dir}" "-Wl,--disable-new-dtags")
endforeach()

target_link_libraries(anthracite m ${X11_LIBRARIES} ${OPENGL_LIBRARIES})

if(CMAKE_BUILD_TYPE STREQUAL "Release")
  target_link_options(anthracite PRIVATE -flto=thin -fuse-ld=lld)
endif()
