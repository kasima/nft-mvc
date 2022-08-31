import unittest
import json
from web3 import Web3
# unittest.TestLoader.sortTestMethodsUsing = None
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

  def test_1_mint(self):
    # mint ID 0 to address
    self.mint_hash = self.erc_721.functions.mint(self.user1.address, 0).transact({'from': self.admin.address})
    owner = self.erc_721.functions.ownerOf(0).call()
    self.assertTrue(owner == self.user1.address)

  def test_2_transfers(self):
    self.erc_721.functions.mint(self.user1.address, 1).transact({'from': self.admin.address})
    self.erc_721.functions.transferFrom(self.user1.address, self.user2.address, 1).transact({'from': self.user1.address})
    new_owner = self.erc_721.functions.ownerOf(1).call()
    self.erc_721.functions.balanceOf(self.user1.address).call()
    self.erc_721.functions.balanceOf(self.user2.address).call()
    self.assertTrue(new_owner == self.user2.address)

  def test_3_approve(self):
    # mint ID 2 to user 1 and check approval
    self.erc_721.functions.mint(self.user1.address, 2).transact({'from': self.admin.address})
    self.erc_721.functions.approve(self.user2.address, 2).transact({'from': self.user1.address})
    approved_addr = self.erc_721.functions.getApproved(2).call()
    self.assertTrue(approved_addr == self.user2.address)
    # check transferFrom is possible
    self.erc_721.functions.transferFrom(self.user1.address, self.user2.address, 2).transact({'from': self.user2.address})
    new_owner = self.erc_721.functions.ownerOf(2).call()
    self.assertTrue(new_owner == self.user2.address)

  def test_4_set_approval_for_all(self):
    # mint ID 3 and 4 to user 2
    self.erc_721.functions.mint(self.user2.address, 3).transact({'from': self.admin.address})
    self.erc_721.functions.mint(self.user2.address, 4).transact({'from': self.admin.address})
    # user 2 sets approve for all for user 1
    self.erc_721.functions.setApprovalForAll(self.user1.address, True).transact({'from': self.user2.address})
    self.erc_721.functions.isApprovedForAll(self.user2.address, self.user1.address).call()
    # user 1 can transfer tokens to self
    self.erc_721.functions.transferFrom(self.user2.address, self.user1.address, 3).transact({'from': self.user1.address})
    self.erc_721.functions.transferFrom(self.user2.address, self.user1.address, 4).transact({'from': self.user1.address})
    owner_3 = self.erc_721.functions.ownerOf(3).call()
    owner_4 = self.erc_721.functions.ownerOf(4).call()
    self.assertTrue(owner_3 == self.user1.address)
    self.assertTrue(owner_4 == self.user1.address)

if __name__ == '__main__':
  unittest.main()
