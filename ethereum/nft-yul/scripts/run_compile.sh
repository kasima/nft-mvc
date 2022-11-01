#!/bin/bash

echo 'compiling contracts'

if [ ! -d 'artifacts' ]; then
  mkdir artifacts
fi

cat ./scripts/yul-compiler-conf.json | solc --standard-json > artifacts/ERC721-artifacts.json

echo 'contracts compiled successfully'