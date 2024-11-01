# Copyright (c) 2024-present The Namseokcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

add_executable(test_namseokcoin-qt
  apptests.cpp
  optiontests.cpp
  rpcnestedtests.cpp
  test_main.cpp
  uritests.cpp
  util.cpp
  ../../init/namseokcoin-qt.cpp
)

target_link_libraries(test_namseokcoin-qt
  core_interface
  namseokcoinqt
  test_util
  namseokcoin_node
  Boost::headers
  Qt5::Test
)

import_plugins(test_namseokcoin-qt)

if(ENABLE_WALLET)
  target_sources(test_namseokcoin-qt
    PRIVATE
      addressbooktests.cpp
      wallettests.cpp
      ../../wallet/test/wallet_test_fixture.cpp
  )
endif()

if(NOT QT_IS_STATIC)
  add_custom_command(
    TARGET test_namseokcoin-qt POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_PROPERTY:Qt5::QMinimalIntegrationPlugin,LOCATION_$<UPPER_CASE:$<CONFIG>>> $<TARGET_FILE_DIR:test_namseokcoin-qt>/plugins/platforms
    VERBATIM
  )
endif()

add_test(NAME test_namseokcoin-qt
  COMMAND test_namseokcoin-qt
)
if(WIN32 AND VCPKG_TARGET_TRIPLET)
  # On Windows, vcpkg configures Qt with `-opengl dynamic`, which makes
  # the "minimal" platform plugin unusable due to internal Qt bugs.
  set_tests_properties(test_namseokcoin-qt PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=windows"
  )
endif()

install(TARGETS test_namseokcoin-qt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
