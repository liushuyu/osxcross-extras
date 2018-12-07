cmake_minimum_required(VERSION 3.2)
project(macdylibbundler)
set (QT_MIN_VERSION "5.5.0")

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

if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  if(OSXCROSS_HOST)
    add_definitions(-DOSXCROSS_HOST="${OSXCROSS_HOST}")
  else()
    message(FATAL_ERROR "This is intended to use with osxcross. If you have osxcross prepared, run eval `osxcross-conf`")
  endif(OSXCROSS_HOST)
endif()

add_executable(macdylibbundler
  ./src/Dependency.cpp
  ./src/DylibBundler.cpp
  ./src/Settings.cpp
  ./src/Utils.cpp
  ./src/main.cpp
)
