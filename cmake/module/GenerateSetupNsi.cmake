# Copyright (c) 2023-present The Namseokcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

function(generate_setup_nsi)
  set(abs_top_srcdir ${PROJECT_SOURCE_DIR})
  set(abs_top_builddir ${PROJECT_BINARY_DIR})
  set(PACKAGE_URL ${PROJECT_HOMEPAGE_URL})
  set(PACKAGE_TARNAME "namseokcoin")
  set(NAMSEOKCOIN_GUI_NAME "namseokcoin-qt")
  set(NAMSEOKCOIN_DAEMON_NAME "namseokcoind")
  set(NAMSEOKCOIN_CLI_NAME "namseokcoin-cli")
  set(NAMSEOKCOIN_TX_NAME "namseokcoin-tx")
  set(NAMSEOKCOIN_WALLET_TOOL_NAME "namseokcoin-wallet")
  set(NAMSEOKCOIN_TEST_NAME "test_namseokcoin")
  set(EXEEXT ${CMAKE_EXECUTABLE_SUFFIX})
  configure_file(${PROJECT_SOURCE_DIR}/share/setup.nsi.in ${PROJECT_BINARY_DIR}/namseokcoin-win64-setup.nsi USE_SOURCE_PERMISSIONS @ONLY)
endfunction()
