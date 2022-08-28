#!/bin/bash
echo 'compiling contracts'
cat ./scripts/yul-compiler-conf.json | solc --standard-json > artifacts/ERC721-artifacts.json
echo 'contracts compiled successfully'