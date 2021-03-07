const { expect } = require("chai");
const { utils } = require('ethers');


async function mintAndApprove(amm, atoken, btoken, aamount, bamount, from) {
  await atoken.mint(from, aamount);
  await btoken.mint(from, bamount);
  await atoken.approve(amm.address, aamount);
  await btoken.approve(amm.address, bamount);
}

describe("AmmMVC", function() {
  beforeEach("test setup", async function () {
    this.addresses = await ethers.getSigners();
    const Token = await ethers.getContractFactory("Token");
    this.atoken = await Token.deploy("tokenA", "A");
    this.btoken = await Token.deploy("tokenB", "B");
    await this.atoken.deployed();
    await this.btoken.deployed();
    const Amm = await ethers.getContractFactory("AmmMVCMocked");
    this.amm = await Amm.deploy(this.atoken.address, this.btoken.address, "AB Token LP", "LP-AB");
    await this.amm.deployed();
    const lpAddress = await this.amm.lpTokenAddress();
    this.lptoken = await ethers.getContractAt("LPToken", lpAddress);
  });

  describe("addLiquidity", async function () {
    it("shoud not allow 0 amount inputs", async function () {
      await mintAndApprove(this.amm, this.atoken, this.btoken, 11, 500, this.addresses[0].address);
      await expect(this.amm.addLiquidity(0, 0)).to.be.revertedWith("AmmMVC: amount can't be zero");
      await expect(this.amm.addLiquidity(0, 1)).to.be.revertedWith("AmmMVC: amount can't be zero");
      await expect(this.amm.addLiquidity(1, 0)).to.be.revertedWith("AmmMVC: amount can't be zero");
    });

    it("should allow user to provide liquidity", async function () {
      await mintAndApprove(this.amm, this.atoken, this.btoken, 1, 1, this.addresses[0].address);
      await this.amm.addLiquidity(1, 1);
      expect(await this.amm.getBReserve()).to.be.equal(1);
      expect(await this.amm.getAReserve()).to.be.equal(1);
      expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.be.equal(1);
    });

    it("should enforce proportion of inputs to be the same as existing reserve", async function () {
      await mintAndApprove(this.amm, this.atoken, this.btoken, 200, 200, this.addresses[0].address);
      await this.amm.addLiquidity(100, 100);
      await expect(this.amm.addLiquidity(100, 50)).to.be.revertedWith("AmmMVC: the inputs are not the same ratio as the reserve");
      await expect(this.amm.addLiquidity(50, 100)).to.be.revertedWith("AmmMVC: the inputs are not the same ratio as the reserve");
    });

    it("should mint LP token correctly after the reserve changes", async function () {
      await mintAndApprove(this.amm, this.atoken, this.btoken, 300, 300, this.addresses[0].address);
      await this.amm.addLiquidity(200, 200);
      await this.amm.mockReduceAReserve(100); //mimics IL
      await this.amm.addLiquidity(20, 40); // should return 40 LPtokens due to change in reserve 
      expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.be.equal(240);
    });
    it("should emit an event", async function () {
      await mintAndApprove(this.amm, this.atoken, this.btoken, 200, 200, this.addresses[0].address);
      await expect(this.amm.addLiquidity(200, 200))
        .to.emit(this.amm, "LiquidityAdded")
        .withArgs(this.addresses[0].address, 200, 200, 200);
    });
  });

  describe("removeLiquidity", async function () {
    beforeEach(async function () {
      await mintAndApprove(this.amm, this.atoken, this.btoken, 100, 100, this.addresses[0].address);
      await this.amm.addLiquidity(100, 100);
      await this.lptoken.approve(this.amm.address, 10000000);
    });

    it("shoud not allow 0 amount inputs", async function () {
      await expect(this.amm.removeLiquidity(0)).to.be.revertedWith("AmmMVC: amount can't be zero");
    });

    it("should allow user to withdraw an amount of LP token for underlying", async function () {
      await this.amm.removeLiquidity(100);
      expect(await this.atoken.balanceOf(this.addresses[0].address)).to.equal(100);
      expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(100);
      expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(0);
      expect(await this.amm.getAReserve()).to.equal(0);
      expect(await this.amm.getBReserve()).to.equal(0);
    });

    it("should not allow an amount that exceeds LP token balance", async function () {
      await expect(this.amm.removeLiquidity(101)).to.be.revertedWith("AmmMVC: not enough LP tokens");
    });

    it("should redeem the correct amount of underlying after A reserve changes", async function (){
      await this.amm.mockReduceAReserve(50); //mimics IL
      await mintAndApprove(this.amm, this.atoken, this.btoken, 50, 100, this.addresses[0].address);
      await this.amm.addLiquidity(50, 100);
      await this.amm.removeLiquidity(100);
      expect(await this.amm.getBReserve()).to.equal(100);
      expect(await this.amm.getAReserve()).to.equal(50);
      expect(await this.atoken.balanceOf(this.addresses[0].address)).to.equal(50);
      expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(100);
      expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(100);
    });

    it("should redeem the correct amount of underlying after B reserve changes", async function () {
      await this.amm.mockReduceBReserve(50); //mimics IL
      await mintAndApprove(this.amm, this.atoken, this.btoken, 100, 50, this.addresses[0].address);
      await this.amm.addLiquidity(100, 50);
      await this.amm.removeLiquidity(100);
      expect(await this.amm.getBReserve()).to.equal(50);
      expect(await this.amm.getAReserve()).to.equal(100);
      expect(await this.atoken.balanceOf(this.addresses[0].address)).to.equal(100);
      expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(50);
      expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(100);
    });
    it("should emit an event", async function () {
      // await this.amm.removeLiquidity(100);
      await expect(this.amm.removeLiquidity(100))
        .to.emit(this.amm, "LiquidityRemoved")
        .withArgs(this.addresses[0].address, 100, 100, 100);
    });
  });

  describe("calculateAtoBOutput", async function () {
    const testCases = [
      [46, 10, 500, 1],
      [385, 50, 10000, 2],
      [14, 35, 500, 1],
    ];
    testCases.map(test => {
      it(`should take input ${test[3]}, for Reserve(${test[1]},${test[2]}) and return ${test[0]}`, async function (){
        let [output, areserve, breserve, input] = test;
        await this.amm.setReserves(areserve, breserve);
        expect(await this.amm.calculateAtoBOutput(input)).to.equal(output);
      });
    });
  });

  describe("swapAtoB", async function () {
    it("shoud not allow 0 amount inputs", async function () {
      await expect(this.amm.swapAtoB(0)).to.be.revertedWith("AmmMVC: amount can't be zero");
    });

    const testCases = [
      [46, 10, 500, 1],
      [385, 50, 10000, 2],
      [14, 35, 500, 1],
    ];

    testCases.map(test => {
      it(`should take input ${test[3]}, for Reserve(${test[1]},${test[2]}) and swap out ${test[0]}`, async function (){
        let [output, areserve, breserve, input] = test;
        await mintAndApprove(this.amm, this.atoken, this.btoken, areserve + input, breserve, this.addresses[0].address);
        await this.amm.addLiquidity(areserve, breserve);
        await this.amm.swapAtoB(input);
        expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(output);
      });
    });

  });
});
