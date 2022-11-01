# ERC721 Implementation in Yul

## Installations
1. install solc > v0.8 
2. install python3
3. install web3py
4. install [foundry](https://book.getfoundry.sh/)

## Compilation deployment and tests
1. run the following in project root: `./scripts/run_compile.sh`
2. generate a testnet EVM and RPC endpoint: `anvil`
3. deploy contract to local RPC: `./scripts/run_deploy.py`
4. run unit test against deployed code: `python3 tests/unit.py -v`

## TODO
- [x] first implementation
- [x] clean up codebase and inline documentation
- [x] compilation and simple test harness
- [ ] provide more test cases 
