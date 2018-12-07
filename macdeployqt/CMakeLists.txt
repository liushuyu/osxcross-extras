cmake_minimum_required(VERSION 3.2)
project(macdeployqt)
set (QT_MIN_VERSION "5.5.0")

find_package(Qt5 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
include_directories(${Qt5Core_INCLUDE_DIRS})

# taken from osxcross toolchain file
macro(osxcross_getconf VAR)
  if(NOT ${VAR})
    set(${VAR} "$ENV{${VAR}}")
    if(${VAR})
      set(${VAR} "${${VAR}}" CACHE STRING "${VAR}")
      message(STATUS "Found ${VAR}: ${${VAR}}")
    else()
      message(WARNING "Cannot determine \"${VAR}\"")
    endif()
  endif()
endmacro()

osxcross_getconf(OSXCROSS_HOST)
osxcross_getconf(OSXCROSS_TARGET_DIR)

SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
SET(AUTOUIC_SEARCH_PATHS "${AUTOUIC_SEARCH_PATHS} ${CMAKE_CURRENT_SOURCE_DIR}")

if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  if(OSXCROSS_HOST)
    add_definitions(-DOSXCROSS_HOST="${OSXCROSS_HOST}")
    add_definitions(-DOSXCROSS_TARGET_DIR="${OSXCROSS_TARGET_DIR}")
  else()
    message(FATAL_ERROR "This is intended to use with osxcross. If you have osxcross prepared, run eval `osxcross-conf`")
  endif(OSXCROSS_HOST)
endif()

add_library(shared OBJECT shared/shared.cpp)

add_executable(macdeployqt
  $<TARGET_OBJECTS:shared>
  macdeployqt/main.cpp
)

target_link_libraries(macdeployqt Qt5::Core)

add_executable(macchangeqt
  $<TARGET_OBJECTS:shared>
  macdeployqt/main.cpp
)

target_link_libraries(macchangeqt Qt5::Core)
