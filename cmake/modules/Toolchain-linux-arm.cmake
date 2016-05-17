message(STATUS "Using Linux-arm toolchain file")

if("${CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN}" STREQUAL "")
	message(FATAL_ERROR "You must specify a path to the cross-linker")
endif()

# TOOLCHAINFILE_TRIPLE Must match llvm_host_triple (build-script-impl), and also SWIFT_HOST_VARIANT_ARCH
# swift needs that to find the standard library.
if("${CMAKE_CROSSTOOLS_HOST}" STREQUAL "linux-armv6")
	set(CMAKE_SYSTEM_PROCESSOR "armv6l")
	set(TOOLCHAINFILE_TRIPLE "armv6-linux-gnueabihf")
else()
	set(CMAKE_SYSTEM_PROCESSOR "armv7l")
	set(TOOLCHAINFILE_TRIPLE "armv7-linux-gnueabihf")
endif()

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_EXECUTABLE_FORMAT "ELF")

# This is only 'arm' because it's GCC's triple.
# Used for finding system headers in Glibc/CMakeLists.txt
set(CMAKE_LIBRARY_ARCHITECTURE "arm-linux-gnueabihf")

include(CMakeForceCompiler)

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  set(CMAKE_AR ${CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN}/ar CACHE FILEPATH "Archiver") # https://cmake.rg/Bug/view.php?id=13038
endif ()

set(COMMON_C_FLAGS "-B ${CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN}")
set(COMMON_C_FLAGS "${COMMON_C_FLAGS} -B ${CMAKE_SYSROOT}/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/4.8")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_C_FLAGS}" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_C_FLAGS}" CACHE STRING "" FORCE)

set(CMAKE_CXX_COMPILER_VERSION 3.9)

link_directories(${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/
                 ${CMAKE_SYSROOT}/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/4.8/)
include_directories(SYSTEM
                ${CMAKE_SYSROOT}/usr/include/c++/4.8/
                ${CMAKE_SYSROOT}/usr/include/${CMAKE_LIBRARY_ARCHITECTURE}/c++/4.8/
                ${CMAKE_SYSROOT}/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/4.8/include/
                ${CMAKE_SYSROOT}/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/4.8/include-fixed/)

# Used to find BSD and ICU among other things
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})

set(CMAKE_C_COMPILER_TARGET ${TOOLCHAINFILE_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${TOOLCHAINFILE_TRIPLE})
set(CMAKE_SWIFT_COMPILER_TARGET ${TOOLCHAINFILE_TRIPLE})

CMAKE_FORCE_C_COMPILER("${CMAKE_C_COMPILER}" Clang)
CMAKE_FORCE_CXX_COMPILER("${CMAKE_CXX_COMPILER}" Clang)