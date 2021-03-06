const { expect } = require("chai");

let ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
let REGULAR_ADDRESS_1 = "0xf48017638ADd0DC399DF50408cdE443963aeab25";
let REGULAR_ADDRESS_2 = "0x635B4764D1939DfAcD3a8014726159abC277BecC";

describe("AmmMVCFactory", function() {
  describe("createTokenPair()", async function () {
    beforeEach(async function () {
      const Factory = await ethers.getContractFactory("AmmMVCFactory");
      this.factory = await Factory.deploy();
      await this.factory.deployed();
    });

    it("should revert on 0 address inputs", async function () {
      await expect(this.factory.createTokenPair(ZERO_ADDRESS, ZERO_ADDRESS)).to.be.revertedWith("AmmMVCFactory: invalid address");
      await expect(this.factory.createTokenPair(ZERO_ADDRESS, REGULAR_ADDRESS_1)).to.be.revertedWith("AmmMVCFactory: invalid address");
      await expect(this.factory.createTokenPair(REGULAR_ADDRESS_1, ZERO_ADDRESS)).to.be.revertedWith("AmmMVCFactory: invalid address");
    });

    it("should emit pair creation event", async function () {
      await expect(this.factory.createTokenPair(REGULAR_ADDRESS_1, REGULAR_ADDRESS_2))
        .to.emit(this.factory, "TokenPairCreated")
        .withArgs("0x55652FF92Dc17a21AD6810Cce2F4703fa2339CAE", REGULAR_ADDRESS_1, REGULAR_ADDRESS_2);
    });

    it("should not allow the same token pair to be created again", async function () {
      await expect(this.factory.createTokenPair(REGULAR_ADDRESS_1, REGULAR_ADDRESS_2)); // first token pair
      await expect(this.factory.createTokenPair(REGULAR_ADDRESS_1, REGULAR_ADDRESS_2)).to.be.revertedWith("AmmMVCFactory: pair already exists");
    });

    it("should return true if pairExists", async function () {
      await expect(this.factory.createTokenPair(REGULAR_ADDRESS_1, REGULAR_ADDRESS_2)); // first token pair
      expect(await this.factory.pairExists(REGULAR_ADDRESS_1, REGULAR_ADDRESS_2)).to.be.true;
      expect(await this.factory.pairExists(REGULAR_ADDRESS_2, REGULAR_ADDRESS_1)).to.be.true;
    });

    it("should return the right address for token pair contract", async function () {
      await this.factory.createTokenPair(REGULAR_ADDRESS_1, REGULAR_ADDRESS_2);
      let tokenPair = await this.factory.tokenPairs(0);
      expect({ a: tokenPair.tokenA , b: tokenPair.tokenB }).to.deep.include({a: REGULAR_ADDRESS_1, b: REGULAR_ADDRESS_2});
      let amm = await ethers.getContractAt("AmmMVC", tokenPair.exchange);
      expect(await amm.aTokenAddress()).to.be.equal(REGULAR_ADDRESS_1);
      expect(await amm.bTokenAddress()).to.be.equal(REGULAR_ADDRESS_2);
    });
  });
});
