# Copyright (c) 2023-present The Namseokcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

include_guard(GLOBAL)

function(setup_split_debug_script)
  if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(OBJCOPY ${CMAKE_OBJCOPY})
    set(STRIP ${CMAKE_STRIP})
    configure_file(
      contrib/devtools/split-debug.sh.in split-debug.sh
      FILE_PERMISSIONS OWNER_READ OWNER_EXECUTE
                       GROUP_READ GROUP_EXECUTE
                       WORLD_READ
      @ONLY
    )
  endif()
endfunction()

function(add_maintenance_targets)
  if(NOT PYTHON_COMMAND)
    return()
  endif()

  if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(exe_format MACHO)
  elseif(WIN32)
    set(exe_format PE)
  else()
    set(exe_format ELF)
  endif()

  # In CMake, the components of the compiler invocation are separated into distinct variables:
  #  - CMAKE_CXX_COMPILER: the full path to the compiler binary itself (e.g., /usr/bin/clang++).
  #  - CMAKE_CXX_COMPILER_ARG1: a string containing initial compiler options (e.g., --target=x86_64-apple-darwin -nostdlibinc).
  # By concatenating these variables, we form the complete command line to be passed to a Python script via the CXX environment variable.
  string(STRIP "${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1}" cxx_compiler_command)
  add_custom_target(test-security-check
    COMMAND ${CMAKE_COMMAND} -E env CXX=${cxx_compiler_command} CXXFLAGS=${CMAKE_CXX_FLAGS} LDFLAGS=${CMAKE_EXE_LINKER_FLAGS} ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/devtools/test-security-check.py TestSecurityChecks.test_${exe_format}
    COMMAND ${CMAKE_COMMAND} -E env CXX=${cxx_compiler_command} CXXFLAGS=${CMAKE_CXX_FLAGS} LDFLAGS=${CMAKE_EXE_LINKER_FLAGS} ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/devtools/test-symbol-check.py TestSymbolChecks.test_${exe_format}
    VERBATIM
  )

  foreach(target IN ITEMS namseokcoind namseokcoin-qt namseokcoin-cli namseokcoin-tx namseokcoin-util namseokcoin-wallet test_namseokcoin bench_namseokcoin)
    if(TARGET ${target})
      list(APPEND executables $<TARGET_FILE:${target}>)
    endif()
  endforeach()

  add_custom_target(check-symbols
    COMMAND ${CMAKE_COMMAND} -E echo "Running symbol and dynamic library checks..."
    COMMAND ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/devtools/symbol-check.py ${executables}
    VERBATIM
  )

  if(ENABLE_HARDENING)
    add_custom_target(check-security
      COMMAND ${CMAKE_COMMAND} -E echo "Checking binary security..."
      COMMAND ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/devtools/security-check.py ${executables}
      VERBATIM
    )
  else()
    add_custom_target(check-security)
  endif()
endfunction()

function(add_windows_deploy_target)
  if(MINGW AND TARGET namseokcoin-qt AND TARGET namseokcoind AND TARGET namseokcoin-cli AND TARGET namseokcoin-tx AND TARGET namseokcoin-wallet AND TARGET namseokcoin-util AND TARGET test_namseokcoin)
    # TODO: Consider replacing this code with the CPack NSIS Generator.
    #       See https://cmake.org/cmake/help/latest/cpack_gen/nsis.html
    include(GenerateSetupNsi)
    generate_setup_nsi()
    add_custom_command(
      OUTPUT ${PROJECT_BINARY_DIR}/namseokcoin-win64-setup.exe
      COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_BINARY_DIR}/release
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:namseokcoin-qt> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:namseokcoin-qt>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:namseokcoind> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:namseokcoind>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:namseokcoin-cli> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:namseokcoin-cli>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:namseokcoin-tx> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:namseokcoin-tx>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:namseokcoin-wallet> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:namseokcoin-wallet>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:namseokcoin-util> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:namseokcoin-util>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:test_namseokcoin> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:test_namseokcoin>
      COMMAND makensis -V2 ${PROJECT_BINARY_DIR}/namseokcoin-win64-setup.nsi
      VERBATIM
    )
    add_custom_target(deploy DEPENDS ${PROJECT_BINARY_DIR}/namseokcoin-win64-setup.exe)
  endif()
endfunction()

function(add_macos_deploy_target)
  if(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND TARGET namseokcoin-qt)
    set(macos_app "Namseokcoin-Qt.app")
    # Populate Contents subdirectory.
    configure_file(${PROJECT_SOURCE_DIR}/share/qt/Info.plist.in ${macos_app}/Contents/Info.plist NO_SOURCE_PERMISSIONS)
    file(CONFIGURE OUTPUT ${macos_app}/Contents/PkgInfo CONTENT "APPL????")
    # Populate Contents/Resources subdirectory.
    file(CONFIGURE OUTPUT ${macos_app}/Contents/Resources/empty.lproj CONTENT "")
    configure_file(${PROJECT_SOURCE_DIR}/src/qt/res/icons/namseokcoin.icns ${macos_app}/Contents/Resources/namseokcoin.icns NO_SOURCE_PERMISSIONS COPYONLY)
    file(CONFIGURE OUTPUT ${macos_app}/Contents/Resources/Base.lproj/InfoPlist.strings
      CONTENT "{ CFBundleDisplayName = \"@PACKAGE_NAME@\"; CFBundleName = \"@PACKAGE_NAME@\"; }"
    )

    add_custom_command(
      OUTPUT ${PROJECT_BINARY_DIR}/${macos_app}/Contents/MacOS/Namseokcoin-Qt
      COMMAND ${CMAKE_COMMAND} --install ${PROJECT_BINARY_DIR} --config $<CONFIG> --component GUI --prefix ${macos_app}/Contents/MacOS --strip
      COMMAND ${CMAKE_COMMAND} -E rename ${macos_app}/Contents/MacOS/bin/$<TARGET_FILE_NAME:namseokcoin-qt> ${macos_app}/Contents/MacOS/Namseokcoin-Qt
      COMMAND ${CMAKE_COMMAND} -E rm -rf ${macos_app}/Contents/MacOS/bin
      VERBATIM
    )

    string(REPLACE " " "-" osx_volname ${PACKAGE_NAME})
    if(CMAKE_HOST_APPLE)
      add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/${osx_volname}.zip
        COMMAND ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/macdeploy/macdeployqtplus ${macos_app} ${osx_volname} -translations-dir=${QT_TRANSLATIONS_DIR} -zip
        DEPENDS ${PROJECT_BINARY_DIR}/${macos_app}/Contents/MacOS/Namseokcoin-Qt
        VERBATIM
      )
      add_custom_target(deploydir
        DEPENDS ${PROJECT_BINARY_DIR}/${osx_volname}.zip
      )
      add_custom_target(deploy
        DEPENDS ${PROJECT_BINARY_DIR}/${osx_volname}.zip
      )
    else()
      add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/dist/${macos_app}/Contents/MacOS/Namseokcoin-Qt
        COMMAND OBJDUMP=${CMAKE_OBJDUMP} ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/macdeploy/macdeployqtplus ${macos_app} ${osx_volname} -translations-dir=${QT_TRANSLATIONS_DIR}
        DEPENDS ${PROJECT_BINARY_DIR}/${macos_app}/Contents/MacOS/Namseokcoin-Qt
        VERBATIM
      )
      add_custom_target(deploydir
        DEPENDS ${PROJECT_BINARY_DIR}/dist/${macos_app}/Contents/MacOS/Namseokcoin-Qt
      )

      find_program(ZIP_COMMAND zip REQUIRED)
      add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/dist/${osx_volname}.zip
        WORKING_DIRECTORY dist
        COMMAND ${PROJECT_SOURCE_DIR}/cmake/script/macos_zip.sh ${ZIP_COMMAND} ${osx_volname}.zip
        VERBATIM
      )
      add_custom_target(deploy
        DEPENDS ${PROJECT_BINARY_DIR}/dist/${osx_volname}.zip
      )
    endif()
    add_dependencies(deploydir namseokcoin-qt)
    add_dependencies(deploy deploydir)
  endif()
endfunction()
