# NFT.MVC

Introducing NFT.MVC. We felt that the crypto space needed a chain-agnostic, developer-focused resource to compare various smart contract platforms, whether they be L1s, L2s, bridges, etc.

Inspired by [TodoMVC](https://todomvc.com/), our goal is to build functionally identical non-fungible token contract on all smart contract platforms.

We aim to demonstrate the language, frameworks, deployment, and tooling for all supported platforms. Contracts will be built to the same test suite, as best we can, and use the same front end app.


## What's Implemented

- NFT contracts (inspired by [EIP-721](https://eips.ethereum.org/EIPS/eip-721))
- Tests
- Deployment scripts
- Framework, if applicable
- Web frontend
- Live on a testnet


## Supported Chains / Platforms / Languages / Frameworks

- Ethereum
  - Languages
    - Solidity / Hardhat
    - Vyper
    - YUL
- Optimism
- Arbitrum
- ZKSync
- StarkNet
  - Cairo
  - Solidity compiler
- Solana
- Polkadot
- Avalanche


## Test Suite

```
describe "constructor()"
  it "mints specified number of NFTs"

describe "balanceOf()"
  it "returns the number of NFTs owned by an address"

describe "ownerOf()"
  it "returns the owner address of a tokenID"

describe "transferFrom()"
  it "changes the owner of a tokenID if called by the current owner"
  it "emits a Transfer event"

  it "does not change the owner if not called by owner, approved, or operator"

describe "approve()"
  it "allows transferFrom for an approved address"
  it "emits an Approve event"

  it "does not approve if not called by the owner"

describe "setApprovalForAll()"
  it "allows transferFrom for all tokens owned by caller for operator addresses"
  it "emits an ApprovalForAll event"

  it "does not approve for tokens not owned by caller"

describe "getApproved()"
  it "returns the approved address of a tokenID"

describe "isApprovedForAll()"
  it "returns True if operator is approved for owner's NFT"
```


## Contributions

All contributions welcome. Supported platforms are currently chosen by our own interest. But we do not descriminate on platforms as long as implementation requirements are met.


## Resources
- [EIP-721](https://eips.ethereum.org/EIPS/eip-721)
