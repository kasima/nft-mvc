import json
from web3 import Web3

def do_deploy():
  w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

  f = open('./artifacts/ERC721-artifacts.json')
  conf = json.load(f)
  TESTNET_MNEMONIC =  "test test test test test test test test test test test junk"
  w3.eth.account.enable_unaudited_hdwallet_features()
  account = w3.eth.account.from_mnemonic(TESTNET_MNEMONIC, account_path="m/44'/60'/0'/0/0")

  signed_txn = w3.eth.account.sign_transaction(dict(
      nonce=w3.eth.get_transaction_count(account.address),
      maxFeePerGas=3000000000,
      maxPriorityFeePerGas=2000000000,
      gas=450000,
      to='',
      value=0,
      data='0x'+conf['contracts']['ERC721.yul']['721']['evm']['bytecode']['object']
    ),
    account.privateKey
  )

  tx = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
  with open('./artifacts/deploy.txt', 'w') as f:
    f.write(tx.hex())