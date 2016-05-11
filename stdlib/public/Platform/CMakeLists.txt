set(swift_platform_name)
set(swift_platform_flags)
set(swift_platform_sources
    Platform.swift
    Misc.c
    tgmath.swift.gyb)

if(SWIFT_HOST_VARIANT MATCHES "${SWIFT_DARWIN_VARIANTS}")
  set(swift_platform_name swiftDarwin)
  set(swift_platform_sources
      Darwin.swift
      ${swift_platform_sources}
      POSIXError.swift
      MachError.swift)
  set(swift_platform_flags
      SWIFT_COMPILE_FLAGS -Xfrontend -disable-objc-attr-requires-foundation-module
      API_NOTES_NON_OVERLAY)
else()
  set(swift_platform_name swiftGlibc)
  set(swift_platform_sources
      Glibc.swift
      ${swift_platform_sources})
  set(swift_platform_flags
      DEPENDS glibc_modulemap)
endif()

add_swift_library(${swift_platform_name} IS_SDK_OVERLAY
    ${swift_platform_sources}
    ${swift_platform_flags})

set(glibc_modulemap_target_list)
foreach(sdk ${SWIFT_SDKS})
  if("${sdk}" STREQUAL "LINUX" OR
     "${sdk}" STREQUAL "FREEBSD" OR
     "${sdk}" STREQUAL "ANDROID" OR
     "${sdk}" STREQUAL "CYGWIN")
    foreach(arch ${SWIFT_SDK_${sdk}_ARCHITECTURES})
      set(arch_subdir "${SWIFT_SDK_${sdk}_LIB_SUBDIR}/${arch}")
      set(module_dir "${SWIFTLIB_DIR}/${arch_subdir}")

      # Determine the location of glibc headers based on the target.
      set(GLIBC_NATIVE_INCLUDE_PATH "/usr/include")
      set(GLIBC_NATIVE_ARCH_INCLUDE_PATH ${GLIBC_NATIVE_INCLUDE_PATH})
      # Some SDKs place their headers in architecture-specific subfolders.
      if((${sdk} STREQUAL "LINUX" OR ${sdk} STREQUAL "FREEBSD") AND CMAKE_LIBRARY_ARCHITECTURE)
        set(GLIBC_NATIVE_ARCH_INCLUDE_PATH "${GLIBC_NATIVE_ARCH_INCLUDE_PATH}/${CMAKE_LIBRARY_ARCHITECTURE}")
      endif()

      # Android uses a different sysroot variable, although there are pending PRs to refactor this
      if(${sdk} STREQUAL "ANDROID")
        set(GLIBC_SYSTEM_ROOT "${SWIFT_ANDROID_SDK_PATH}")
      else()
        set(GLIBC_SYSTEM_ROOT "${CMAKE_SYSROOT}")
      endif()

      set(GLIBC_INCLUDE_PATH "${GLIBC_SYSTEM_ROOT}/${GLIBC_NATIVE_INCLUDE_PATH}")
      set(GLIBC_ARCH_INCLUDE_PATH ${GLIBC_SYSTEM_ROOT}/${GLIBC_NATIVE_ARCH_INCLUDE_PATH})

      set(glibc_modulemap_source "glibc.modulemap.gyb")
      set(glibc_modulemap_out "${module_dir}/glibc.modulemap")

      # Configure the module map based on the target. Each platform needs to
      # reference different headers, based on what's available in their glibc.
      handle_gyb_source_single(glibc_modulemap_target
          SOURCE "${glibc_modulemap_source}"
          OUTPUT "${glibc_modulemap_out}"
          FLAGS
              "-DCMAKE_SDK=${sdk}"
              "-DGLIBC_INCLUDE_PATH=${GLIBC_INCLUDE_PATH}"
              "-DGLIBC_ARCH_INCLUDE_PATH=${GLIBC_ARCH_INCLUDE_PATH}")

      list(APPEND glibc_modulemap_target_list ${glibc_modulemap_target})

      # If cross-compiling, generate a native modulemap without the sysroot prefix
      # The prefixed one is still the 'glibc.modulemap' which we'll look at during the build process
      if(CMAKE_CROSSCOMPILING)
        set(glibc_native_modulemap_out "${module_dir}/native-substitutes/glibc.modulemap")
        handle_gyb_source_single(glibc_modulemap_native_target
            SOURCE "${glibc_modulemap_source}"
            OUTPUT "${glibc_native_modulemap_out}"
            FLAGS
                "-DCMAKE_SDK=${sdk}"
                "-DGLIBC_INCLUDE_PATH=${GLIBC_NATIVE_INCLUDE_PATH}"
                "-DGLIBC_ARCH_INCLUDE_PATH=${GLIBC_NATIVE_ARCH_INCLUDE_PATH}")

        list(APPEND glibc_modulemap_target_list ${glibc_modulemap_native_target})
        set(glibc_modulemap_out ${glibc_native_modulemap_out})
      endif()
        
      swift_install_in_component(sdk-overlay
          FILES "${glibc_modulemap_out}"
          DESTINATION "lib/swift/${arch_subdir}")

    endforeach()
  endif()
endforeach()
add_custom_target(glibc_modulemap DEPENDS ${glibc_modulemap_target_list})
