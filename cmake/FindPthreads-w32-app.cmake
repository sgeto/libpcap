# ==============================================================================
# This is a heavily modified version of FindPthreads.cmake for the pcap project.
# It's meant to find Pthreads-w32, an implementation of the
# Threads component of the POSIX 1003.1c 1995 Standard (or later)
# for Microsoft's WIndows.
#
# Apart from this notice, this module "enjoys" the following modifications:
#
# - changed its name to FindPthreads-w32.cmake to not conflict with FindThreads.cmake
#
# - users may be able to use the environment variable PTHREADS_ROOT to point
#   cmake to the *root* of their Pthreads-w32 installation.
#   Alternatively, PTHREADS_ROOT may also be set from cmake command line or GUI
#   (-DPTHREADS_ROOT=/path/to/Pthreads-w32)
#   Two other variables that can be defined in a similar fashion are
#   PTHREAD_INCLUDE_PATH and PTHREAD_LIBRARY_PATH.
#
# - added some additional status/error messages
#
# - changed formating (uppercase to lowercare + indentation)
#
# - removed some stuff
#
# - when searching for Pthreads-win32 libraries, the directory structure of the
#   pre-build binaries folder found in the pthreads-win32 CVS code repository is
#   considered (e.i /Pre-built.2/lib/x64 /Pre-built.2/lib/x86)
#
# Send suggestion, patches, gifts and praises to pcap's developers.
# ==============================================================================
#
# Find the Pthreads library
# This module searches for the Pthreads-win32 library (including the
# pthreads-win32 port).
#
# This module defines these variables:
#
#  PTHREADS_FOUND       - True if the Pthreads library was found
#  PTHREADS_LIBRARY     - The location of the Pthreads library
#  PTHREADS_INCLUDE_DIR - The include directory of the Pthreads library
#  PTHREADS_DEFINITIONS - Preprocessor definitions to define (HAVE_PTHREAD_H is a fairly common one)
#
# This module responds to the PTHREADS_EXCEPTION_SCHEME
# variable on Win32 to allow the user to control the
# library linked against. The Pthreads-win32 port
# provides the ability to link against a version of the
# library with exception handling.
# IT IS NOT RECOMMENDED THAT YOU CHANGE PTHREADS_EXCEPTION_SCHEME
# TO ANYTHING OTHER THAN "C" because most POSIX thread implementations
# do not support stack unwinding.
#
#  PTHREADS_EXCEPTION_SCHEME
#       C  = no exceptions (default)
#           (NOTE: This is the default scheme on most POSIX thread
#           implementations and what you should probably be using)
#       CE = C++ Exception Handling
#       SE = Structure Exception Handling (MSVC only)
#

#
# Define a default exception scheme to link against
# and validate user choice.
#
#
if(NOT DEFINED PTHREADS_EXCEPTION_SCHEME)
  # Assign default if needed
  set(PTHREADS_EXCEPTION_SCHEME "C")
else(NOT DEFINED PTHREADS_EXCEPTION_SCHEME)
  # Validate
  if(NOT PTHREADS_EXCEPTION_SCHEME STREQUAL "C" AND
    NOT PTHREADS_EXCEPTION_SCHEME STREQUAL "CE" AND
    NOT PTHREADS_EXCEPTION_SCHEME STREQUAL "SE")

    message(FATAL_ERROR "See documentation for FindPthreads.cmake, only C, CE, and SE modes are allowed")

  endif(NOT PTHREADS_EXCEPTION_SCHEME STREQUAL "C" AND
    NOT PTHREADS_EXCEPTION_SCHEME STREQUAL "CE" AND
    NOT PTHREADS_EXCEPTION_SCHEME STREQUAL "SE")

  if(NOT MSVC AND PTHREADS_EXCEPTION_SCHEME STREQUAL "SE")
    message(FATAL_ERROR "Structured Exception Handling is only allowed for MSVC")
  endif(NOT MSVC AND PTHREADS_EXCEPTION_SCHEME STREQUAL "SE")

endif(NOT DEFINED PTHREADS_EXCEPTION_SCHEME)

if(GET_PTHREADS)


I assume you already have a zip-tool installed (WinZip or 7z, etc.). You could write a find_zip-tool script which will search for WinZip, or 7Z, etc...

Snippet for WinZip:

FIND_PROGRAM(ZIP_EXECUTABLE wzzip PATHS "$ENV{ProgramFiles}/WinZip")
IF(ZIP_EXECUTABLE)
  SET(ZIP_COMMAND "\"${ZIP_EXECUTABLE}\" -P \"<ARCHIVE>\" @<FILELIST>")
ENDIF(ZIP_EXECUTABLE)
Snippet for 7-zip:

  FIND_PROGRAM(ZIP_EXECUTABLE 7z PATHS "$ENV{ProgramFiles}/7-Zip") 
  IF(ZIP_EXECUTABLE)
    SET(ZIP_COMMAND "\"${ZIP_EXECUTABLE}\" a -tzip \"<ARCHIVE>\" @<FILELIST>")
  ENDIF(ZIP_EXECUTABLE)
Take a look at the file

<cmake-install-dir>\share\cmake-2.8\Modules\CPackZIP.cmake
it shows how CPack searches for a Zip_Executable and prepares some "useful" default flags.

After that, I would suggest to execute_process, similar to sakra's answer


# Check whether the source has been downloaded. If true, skip it.
# Useful for external downloads like homebrew.
  # Download it
  file(DOWNLOAD
  # ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip
  file:///C:/Users/Ali/Downloads/Compressed/pthreads-w32-2-9-1-release.zip
  ${CMAKE_BINARY_DIR}/pthreads-w32-2-9-1-release.zip
  EXPECTED_HASH SHA512=9282d56d5fbc8c09f31d3b67f2504781968c39703e8fb2d9e7663f5f7c2873caed4654d434e4bf7428d414c5b778c263069bdb9453ed2a89ddb0083791ccdeac
  STATUS GET_PTHREADS_STATUS
  )

  message(STATUS "extracting...
    src='${CMAKE_BINARY_DIR}/pthreads-w32-2-9-1-release.zip'
    dst='${CMAKE_BINARY_DIR}'")

  # Extract it
  message(STATUS "extracting... [tar xfz]")
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${CMAKE_BINARY_DIR}/pthreads-w32-2-9-1-release.zip
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  RESULT_VARIABLE RV)

  if(NOT RV EQUAL 0)
    message(FATAL_ERROR "error: extract of 'pthreads-w32-2-9-1-release.zip' failed")
  endif()

  # Clean up
  message(STATUS "extracting... [clean up]")
  file(REMOVE_RECURSE "${CMAKE_BINARY_DIR}/pthreads.2" "${CMAKE_BINARY_DIR}/QueueUserAPCEx")

  message(STATUS "extracting... done")

  # Patch it
  message(STATUS "patching... ")
  file(GLOB HEADERS "${CMAKE_BINARY_DIR}/Pre-built.2/include/*.h")
  foreach(HEADER ${HEADERS})
    file(READ "${HEADER}" _contents)
    string(REPLACE "defined(_TIMESPEC_DEFINED)" "1" _contents "${_contents}")
    string(REPLACE "defined(PTW32_RC_MSC)" "1" _contents "${_contents}")
    # if(LIBRARY_LINKAGE STREQUAL static)
      # string(REPLACE "!defined(PTW32_STATIC_LIB)" "0" _contents "${_contents}")
    # endif()
    file(WRITE "${HEADER}" "${_contents}")
  endforeach()
  message(STATUS "patching... done")

  set(PTHREADS_ROOT "${CMAKE_BINARY_DIR}/Pre-built.2")

elseif(PTHREADS_ROOT)
  set(PTHREADS_ROOT PATHS ${PTHREADS_ROOT} NO_DEFAULT_PATH)
else()
  set(PTHREADS_ROOT $ENV{PTHREADS_ROOT})
endif(PTHREADS_ROOT)

#
# Find the header file
#
find_path(PTHREADS_INCLUDE_DIR
  NAMES pthread.h
  HINTS
  $ENV{PTHREAD_INCLUDE_PATH}
  ${PTHREADS_ROOT}/include
)

if(PTHREADS_INCLUDE_DIR)
  message(STATUS "Found pthread.h: ${PTHREADS_INCLUDE_DIR}")
# else()
# message(FATAL_ERROR "Could not find pthread.h. See README.Win32 for more information.")
endif(PTHREADS_INCLUDE_DIR)

#
# Find the library
#
set(names)
if(MSVC)
  set(names
      pthreadV${PTHREADS_EXCEPTION_SCHEME}2
      libpthread
  )
elseif(MINGW)
  set(names
      pthreadG${PTHREADS_EXCEPTION_SCHEME}2
      pthread
  )
endif(MSVC)

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
  set(SUBDIR "/x86")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(SUBDIR "/x64")
endif()

find_library(PTHREADS_LIBRARY NAMES ${names}
  DOC "The Portable Threads Library"
  HINTS
  ${CMAKE_SOURCE_DIR}/lib
  $ENV{PTHREAD_LIBRARY_PATH}
  ${PTHREADS_ROOT}
  C:/MinGW/lib/
  PATH_SUFFIXES lib/${SUBDIR}
)

if(PTHREADS_LIBRARY)
message(STATUS "Found PTHREADS library: ${PTHREADS_LIBRARY} (PTHREADS Exception Scheme: ${PTHREADS_EXCEPTION_SCHEME})")
# else()
# message(FATAL_ERROR "Could not find PTHREADS LIBRARY. See README.Win32 for more information.")
endif(PTHREADS_LIBRARY)

if(PTHREADS_INCLUDE_DIR AND PTHREADS_LIBRARY)
  set(PTHREADS_DEFINITIONS -DHAVE_PTHREAD_H)
  set(PTHREADS_INCLUDE_DIRS ${PTHREADS_INCLUDE_DIR})
  set(PTHREADS_LIBRARIES ${PTHREADS_LIBRARY})
  set(PTHREADS_FOUND TRUE)
endif(PTHREADS_INCLUDE_DIR AND PTHREADS_LIBRARY)

mark_as_advanced(PTHREADS_INCLUDE_DIR PTHREADS_LIBRARY)
