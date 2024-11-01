// Copyright (c) 2023-present The Namseokcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef NAMSEOKCOIN_TEST_UTIL_JSON_H
#define NAMSEOKCOIN_TEST_UTIL_JSON_H

#include <univalue.h>

#include <string_view>

UniValue read_json(std::string_view jsondata);

#endif // NAMSEOKCOIN_TEST_UTIL_JSON_H
