// Copyright (c) 2021-2022 The Namseokcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.
//
#ifndef NAMSEOKCOIN_TEST_UTIL_CHAINSTATE_H
#define NAMSEOKCOIN_TEST_UTIL_CHAINSTATE_H

#include <clientversion.h>
#include <logging.h>
#include <node/context.h>
#include <node/utxo_snapshot.h>
#include <rpc/blockchain.h>
#include <test/util/setup_common.h>
#include <util/fs.h>
#include <validation.h>

#include <univalue.h>

const auto NoMalleation = [](AutoFile& file, node::SnapshotMetadata& meta){};

/**
 * Create and activate a UTXO snapshot, optionally providing a function to
 * malleate the snapshot.
 *
 * If `reset_chainstate` is true, reset the original chainstate back to the genesis
 * block. This allows us to simulate more realistic conditions in which a snapshot is
 * loaded into an otherwise mostly-uninitialized datadir. It also allows us to test
 * conditions that would otherwise cause shutdowns based on the IBD chainstate going
 * past the snapshot it generated.
 */
template<typename F = decltype(NoMalleation)>
static bool
CreateAndActivateUTXOSnapshot(
    TestingSetup* fixture,
    F malleation = NoMalleation,
    bool reset_chainstate = false,
    bool in_memory_chainstate = false)
{
    node::NodeContext& node = fixture->m_node;
    fs::path root = fixture->m_path_root;

    // Write out a snapshot to the test's tempdir.
    //
    int height;
    WITH_LOCK(::cs_main, height = node.chainman->ActiveHeight());
    fs::path snapshot_path = root / fs::u8path(tfm::format("test_snapshot.%d.dat", height));
    FILE* outfile{fsbridge::fopen(snapshot_path, "wb")};
    AutoFile auto_outfile{outfile};

    UniValue result = CreateUTXOSnapshot(
        node, node.chainman->ActiveChainstate(), auto_outfile, snapshot_path, snapshot_path);
    LogPrintf(
        "Wrote UTXO snapshot to %s: %s\n", fs::PathToString(snapshot_path.make_preferred()), result.write());

    // Read the written snapshot in and then activate it.
    //
    FILE* infile{fsbridge::fopen(snapshot_path, "rb")};
    AutoFile auto_infile{infile};
    node::SnapshotMetadata metadata{node.chainman->GetParams().MessageStart()};
    auto_infile >> metadata;

    malleation(auto_infile, metadata);

    if (reset_chainstate) {
        {
            // What follows is code to selectively reset chainstate data without
            // disturbing the existing BlockManager instance, which is needed to
            // recognize the headers chain previously generated by the chainstate we're
            // removing. Without those headers, we can't activate the snapshot below.
            //
            // This is a stripped-down version of node::LoadChainstate which
            // preserves the block index.
            LOCK(::cs_main);
            CBlockIndex *orig_tip = node.chainman->ActiveChainstate().m_chain.Tip();
            uint256 gen_hash = node.chainman->ActiveChainstate().m_chain[0]->GetBlockHash();
            node.chainman->ResetChainstates();
            node.chainman->InitializeChainstate(node.mempool.get());
            Chainstate& chain = node.chainman->ActiveChainstate();
            Assert(chain.LoadGenesisBlock());
            // These cache values will be corrected shortly in `MaybeRebalanceCaches`.
            chain.InitCoinsDB(1 << 20, true, false, "");
            chain.InitCoinsCache(1 << 20);
            chain.CoinsTip().SetBestBlock(gen_hash);
            chain.setBlockIndexCandidates.insert(node.chainman->m_blockman.LookupBlockIndex(gen_hash));
            chain.LoadChainTip();
            node.chainman->MaybeRebalanceCaches();

            // Reset the HAVE_DATA flags below the snapshot height, simulating
            // never-having-downloaded them in the first place.
            // TODO: perhaps we could improve this by using pruning to delete
            // these blocks instead
            CBlockIndex *pindex = orig_tip;
            while (pindex && pindex != chain.m_chain.Tip()) {
                // Remove all data and validity flags by just setting
                // BLOCK_VALID_TREE. Also reset transaction counts and sequence
                // ids that are set when blocks are received, to make test setup
                // more realistic and satisfy consistency checks in
                // CheckBlockIndex().
                assert(pindex->IsValid(BlockStatus::BLOCK_VALID_TREE));
                pindex->nStatus = BlockStatus::BLOCK_VALID_TREE;
                pindex->nTx = 0;
                pindex->m_chain_tx_count = 0;
                pindex->nSequenceId = 0;
                pindex = pindex->pprev;
            }
        }
        BlockValidationState state;
        if (!node.chainman->ActiveChainstate().ActivateBestChain(state)) {
            throw std::runtime_error(strprintf("ActivateBestChain failed. (%s)", state.ToString()));
        }
        Assert(
            0 == WITH_LOCK(node.chainman->GetMutex(), return node.chainman->ActiveHeight()));
    }

    auto& new_active = node.chainman->ActiveChainstate();
    auto* tip = new_active.m_chain.Tip();

    // Disconnect a block so that the snapshot chainstate will be ahead, otherwise
    // it will refuse to activate.
    //
    // TODO this is a unittest-specific hack, and we should probably rethink how to
    // better generate/activate snapshots in unittests.
    if (tip->pprev) {
        new_active.m_chain.SetTip(*(tip->pprev));
    }

    auto res = node.chainman->ActivateSnapshot(auto_infile, metadata, in_memory_chainstate);

    // Restore the old tip.
    new_active.m_chain.SetTip(*tip);
    return !!res;
}


#endif // NAMSEOKCOIN_TEST_UTIL_CHAINSTATE_H
