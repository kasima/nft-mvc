import unittest
import json
from web3 import Web3
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))
TESTNET_MNEMONIC =  "test test test test test test test test test test test junk"
w3.eth.account.enable_unaudited_hdwallet_features()

class ERC721Test(unittest.TestCase):
  def setUp(self):
    with open('./artifacts/deploy.txt') as f:
      txhash = f.read()
      txreceipt = w3.eth.get_transaction_receipt(txhash)
      erc_721_address = txreceipt['contractAddress']
    self.admin = w3.eth.account.from_mnemonic(TESTNET_MNEMONIC, account_path="m/44'/60'/0'/0/0")
    self.user1 = w3.eth.account.from_mnemonic(TESTNET_MNEMONIC, account_path="m/44'/60'/0'/0/1")
    self.user2 = w3.eth.account.from_mnemonic(TESTNET_MNEMONIC, account_path="m/44'/60'/0'/0/2")
    with open('./abi/IERC721.json') as json_file:
      abi = json.load(json_file)
    self.erc_721 = w3.eth.contract(address=erc_721_address, abi=abi)

  def test_mint(self):
    # mint ID 0 to address
    mint_hash = self.erc_721.functions.mint(self.user1.address, 1).transact({'from': self.admin.address})
    w3.eth.wait_for_transaction_receipt(mint_hash)
    owner = self.erc_721.functions.ownerOf(1).call()
    balance = self.erc_721.functions.balanceOf(self.user1.address).call()
    self.assertTrue(balance == 1)
    self.assertTrue(owner == self.user1.address)

  def test_transfers(self):
    transfer_hash = self.erc_721.functions.transferFrom(self.user1.address, self.user2.address, 1).transact({'from': self.user1.address})
    w3.eth.wait_for_transaction_receipt(transfer_hash)
    new_owner = self.erc_721.functions.ownerOf(1).call()
    prev_balance = self.erc_721.functions.balanceOf(self.user1.address).call()
    new_balance = self.erc_721.functions.balanceOf(self.user2.address).call()
    self.assertTrue(prev_balance == 0)
    self.assertTrue(new_balance == 1)
    self.assertTrue(new_owner == self.user2.address)

  
if __name__ == '__main__':
  unittest.main()