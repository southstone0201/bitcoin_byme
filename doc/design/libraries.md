# Libraries

| Name                     | Description |
|--------------------------|-------------|
| *libnamseokcoin_cli*         | RPC client functionality used by *namseokcoin-cli* executable |
| *libnamseokcoin_common*      | Home for common functionality shared by different executables and libraries. Similar to *libnamseokcoin_util*, but higher-level (see [Dependencies](#dependencies)). |
| *libnamseokcoin_consensus*   | Consensus functionality used by *libnamseokcoin_node* and *libnamseokcoin_wallet*. |
| *libnamseokcoin_crypto*      | Hardware-optimized functions for data encryption, hashing, message authentication, and key derivation. |
| *libnamseokcoin_kernel*      | Consensus engine and support library used for validation by *libnamseokcoin_node*. |
| *libnamseokcoinqt*           | GUI functionality used by *namseokcoin-qt* and *namseokcoin-gui* executables. |
| *libnamseokcoin_ipc*         | IPC functionality used by *namseokcoin-node*, *namseokcoin-wallet*, *namseokcoin-gui* executables to communicate when [`-DWITH_MULTIPROCESS=ON`](multiprocess.md) is used. |
| *libnamseokcoin_node*        | P2P and RPC server functionality used by *namseokcoind* and *namseokcoin-qt* executables. |
| *libnamseokcoin_util*        | Home for common functionality shared by different executables and libraries. Similar to *libnamseokcoin_common*, but lower-level (see [Dependencies](#dependencies)). |
| *libnamseokcoin_wallet*      | Wallet functionality used by *namseokcoind* and *namseokcoin-wallet* executables. |
| *libnamseokcoin_wallet_tool* | Lower-level wallet functionality used by *namseokcoin-wallet* executable. |
| *libnamseokcoin_zmq*         | [ZeroMQ](../zmq.md) functionality used by *namseokcoind* and *namseokcoin-qt* executables. |

## Conventions

- Most libraries are internal libraries and have APIs which are completely unstable! There are few or no restrictions on backwards compatibility or rules about external dependencies. An exception is *libnamseokcoin_kernel*, which, at some future point, will have a documented external interface.

- Generally each library should have a corresponding source directory and namespace. Source code organization is a work in progress, so it is true that some namespaces are applied inconsistently, and if you look at [`add_library(namseokcoin_* ...)`](../../src/CMakeLists.txt) lists you can see that many libraries pull in files from outside their source directory. But when working with libraries, it is good to follow a consistent pattern like:

  - *libnamseokcoin_node* code lives in `src/node/` in the `node::` namespace
  - *libnamseokcoin_wallet* code lives in `src/wallet/` in the `wallet::` namespace
  - *libnamseokcoin_ipc* code lives in `src/ipc/` in the `ipc::` namespace
  - *libnamseokcoin_util* code lives in `src/util/` in the `util::` namespace
  - *libnamseokcoin_consensus* code lives in `src/consensus/` in the `Consensus::` namespace

## Dependencies

- Libraries should minimize what other libraries they depend on, and only reference symbols following the arrows shown in the dependency graph below:

<table><tr><td>

```mermaid

%%{ init : { "flowchart" : { "curve" : "basis" }}}%%

graph TD;

namseokcoin-cli[namseokcoin-cli]-->libnamseokcoin_cli;

namseokcoind[namseokcoind]-->libnamseokcoin_node;
namseokcoind[namseokcoind]-->libnamseokcoin_wallet;

namseokcoin-qt[namseokcoin-qt]-->libnamseokcoin_node;
namseokcoin-qt[namseokcoin-qt]-->libnamseokcoinqt;
namseokcoin-qt[namseokcoin-qt]-->libnamseokcoin_wallet;

namseokcoin-wallet[namseokcoin-wallet]-->libnamseokcoin_wallet;
namseokcoin-wallet[namseokcoin-wallet]-->libnamseokcoin_wallet_tool;

libnamseokcoin_cli-->libnamseokcoin_util;
libnamseokcoin_cli-->libnamseokcoin_common;

libnamseokcoin_consensus-->libnamseokcoin_crypto;

libnamseokcoin_common-->libnamseokcoin_consensus;
libnamseokcoin_common-->libnamseokcoin_crypto;
libnamseokcoin_common-->libnamseokcoin_util;

libnamseokcoin_kernel-->libnamseokcoin_consensus;
libnamseokcoin_kernel-->libnamseokcoin_crypto;
libnamseokcoin_kernel-->libnamseokcoin_util;

libnamseokcoin_node-->libnamseokcoin_consensus;
libnamseokcoin_node-->libnamseokcoin_crypto;
libnamseokcoin_node-->libnamseokcoin_kernel;
libnamseokcoin_node-->libnamseokcoin_common;
libnamseokcoin_node-->libnamseokcoin_util;

libnamseokcoinqt-->libnamseokcoin_common;
libnamseokcoinqt-->libnamseokcoin_util;

libnamseokcoin_util-->libnamseokcoin_crypto;

libnamseokcoin_wallet-->libnamseokcoin_common;
libnamseokcoin_wallet-->libnamseokcoin_crypto;
libnamseokcoin_wallet-->libnamseokcoin_util;

libnamseokcoin_wallet_tool-->libnamseokcoin_wallet;
libnamseokcoin_wallet_tool-->libnamseokcoin_util;

classDef bold stroke-width:2px, font-weight:bold, font-size: smaller;
class namseokcoin-qt,namseokcoind,namseokcoin-cli,namseokcoin-wallet bold
```
</td></tr><tr><td>

**Dependency graph**. Arrows show linker symbol dependencies. *Crypto* lib depends on nothing. *Util* lib is depended on by everything. *Kernel* lib depends only on consensus, crypto, and util.

</td></tr></table>

- The graph shows what _linker symbols_ (functions and variables) from each library other libraries can call and reference directly, but it is not a call graph. For example, there is no arrow connecting *libnamseokcoin_wallet* and *libnamseokcoin_node* libraries, because these libraries are intended to be modular and not depend on each other's internal implementation details. But wallet code is still able to call node code indirectly through the `interfaces::Chain` abstract class in [`interfaces/chain.h`](../../src/interfaces/chain.h) and node code calls wallet code through the `interfaces::ChainClient` and `interfaces::Chain::Notifications` abstract classes in the same file. In general, defining abstract classes in [`src/interfaces/`](../../src/interfaces/) can be a convenient way of avoiding unwanted direct dependencies or circular dependencies between libraries.

- *libnamseokcoin_crypto* should be a standalone dependency that any library can depend on, and it should not depend on any other libraries itself.

- *libnamseokcoin_consensus* should only depend on *libnamseokcoin_crypto*, and all other libraries besides *libnamseokcoin_crypto* should be allowed to depend on it.

- *libnamseokcoin_util* should be a standalone dependency that any library can depend on, and it should not depend on other libraries except *libnamseokcoin_crypto*. It provides basic utilities that fill in gaps in the C++ standard library and provide lightweight abstractions over platform-specific features. Since the util library is distributed with the kernel and is usable by kernel applications, it shouldn't contain functions that external code shouldn't call, like higher level code targeted at the node or wallet. (*libnamseokcoin_common* is a better place for higher level code, or code that is meant to be used by internal applications only.)

- *libnamseokcoin_common* is a home for miscellaneous shared code used by different Namseokcoin Core applications. It should not depend on anything other than *libnamseokcoin_util*, *libnamseokcoin_consensus*, and *libnamseokcoin_crypto*.

- *libnamseokcoin_kernel* should only depend on *libnamseokcoin_util*, *libnamseokcoin_consensus*, and *libnamseokcoin_crypto*.

- The only thing that should depend on *libnamseokcoin_kernel* internally should be *libnamseokcoin_node*. GUI and wallet libraries *libnamseokcoinqt* and *libnamseokcoin_wallet* in particular should not depend on *libnamseokcoin_kernel* and the unneeded functionality it would pull in, like block validation. To the extent that GUI and wallet code need scripting and signing functionality, they should be get able it from *libnamseokcoin_consensus*, *libnamseokcoin_common*, *libnamseokcoin_crypto*, and *libnamseokcoin_util*, instead of *libnamseokcoin_kernel*.

- GUI, node, and wallet code internal implementations should all be independent of each other, and the *libnamseokcoinqt*, *libnamseokcoin_node*, *libnamseokcoin_wallet* libraries should never reference each other's symbols. They should only call each other through [`src/interfaces/`](../../src/interfaces/) abstract interfaces.

## Work in progress

- Validation code is moving from *libnamseokcoin_node* to *libnamseokcoin_kernel* as part of [The libnamseokcoinkernel Project #27587](https://github.com/namseokcoin/namseokcoin/issues/27587)
