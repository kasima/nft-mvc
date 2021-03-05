const { expect } = require("chai");

async function mintAndApprove(amm, atoken, btoken, aamount, bamount, from) {
  await atoken.mint(from, aamount);
  await btoken.mint(from, bamount);
  await atoken.approve(amm.address, aamount);
  await btoken.approve(amm.address, bamount);
}

describe("AmmMVC", function() {
  beforeEach("test setup", async function () {
    this.addresses = await ethers.getSigners()
    const Token = await ethers.getContractFactory("Token");
    this.atoken = await Token.deploy("tokenA", "A");
    this.btoken = await Token.deploy("tokenB", "B");
    await this.atoken.deployed();
    await this.btoken.deployed();
    const Amm = await ethers.getContractFactory("AmmMVC");
    this.amm = await Amm.deploy(this.atoken.address, this.btoken.address, "AB Token LP", "LP-AB");
    await this.amm.deployed();
    const lpAddress = await this.amm.lpTokenAddress();
    this.lptoken = await ethers.getContractAt("LPToken", lpAddress);
  })

  it("should mint and redeem LPtokens", async function () {
    await mintAndApprove(this.amm, this.atoken, this.btoken, 11, 500, this.addresses[0].address);
    await this.amm.addLiquidity(11, 500);
    expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(11);
    expect(await this.amm.getAReserve()).to.equal(11);
    expect(await this.amm.getBReserve()).to.equal(500);

    await this.lptoken.approve(this.amm.address, 11);
    await this.amm.removeLiquidity(11);
    expect(await this.amm.getBReserve()).to.equal(0);
    expect(await this.amm.getAReserve()).to.equal(0);
  })

  it("should mint the correct proportion of LPtokens after first deposit", async function () {
    await mintAndApprove(this.amm, this.atoken, this.btoken, 150, 750, this.addresses[0].address);
    await this.amm.addLiquidity(100, 500);
    expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(100);
    expect(await this.amm.getAReserve()).to.equal(100);
    expect(await this.amm.getBReserve()).to.equal(500);

    await this.amm.addLiquidity(50, 250);
    expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(150);
    expect(await this.amm.getAReserve()).to.equal(150);
    expect(await this.amm.getBReserve()).to.equal(750);

    await this.lptoken.approve(this.amm.address, 150);
    await this.amm.removeLiquidity(50);
    expect(await this.amm.getAReserve()).to.equal(100);
    expect(await this.amm.getBReserve()).to.equal(500);

    await this.amm.removeLiquidity(100);
    expect(await this.amm.getAReserve()).to.equal(0);
    expect(await this.amm.getBReserve()).to.equal(0);
    expect(await this.atoken.balanceOf(this.addresses[0].address)).to.equal(150);
    expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(750);
  })

  it("should swap a tokens for b tokens", async function() {
    await mintAndApprove(this.amm, this.atoken, this.btoken, 11, 500, this.addresses[0].address);
    await this.amm.addLiquidity(10, 500);

    // Buyer sends: 1 A
    // A_pool = 10 + 1 = 11
    // B_pool = 5000/11 = 454
    // Buyer receieves: 500 - 454 = 46 B

    expect(await this.amm.calculateAtoBOutput(1)).to.equal(46);
    await this.amm.swapAtoB(1);
    expect(await this.amm.getBReserve()).to.equal(454);
    expect(await this.amm.getAReserve()).to.equal(11);
    expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(46);
    await this.lptoken.approve(this.amm.address, 10);
    await this.amm.removeLiquidity(10);
    expect(await this.atoken.balanceOf(this.addresses[0].address)).to.equal(11);
    expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(500);
  });
});
