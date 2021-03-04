const { expect } = require("chai");

describe("AmmMVC", function() {
  before("setup test", async function () {
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

  it("swap", async function() {
    // A_pool = 10
    // B_pool = 500
    // invariant = 10 * 500 = 5000

    await this.atoken.mint(this.addresses[0].address, 11);
    await this.btoken.mint(this.addresses[0].address, 500);
    await this.atoken.approve(this.amm.address, 11);
    await this.btoken.approve(this.amm.address, 500);
    await this.amm.addLiquidity(10, 500);
    expect(await this.lptoken.balanceOf(this.addresses[0].address)).to.equal(5000);
    expect(await this.amm.getAReserve()).to.equal(10);
    expect(await this.amm.getBReserve()).to.equal(500);

    // Buyer sends: 1 A
    // A_pool = 10 + 1 = 11
    // B_pool = 5000/11 = 454
    // Buyer receieves: 500 - 454 = 46 B

    expect(await this.amm.getAtoBOutput(1)).to.equal(46);
    await this.amm.swapAtoB(1);
    expect(await this.amm.getBReserve()).to.equal(454);
    expect(await this.amm.getAReserve()).to.equal(11);

    await this.lptoken.approve(this.amm.address, 5000);
    await this.amm.removeLiquidity(5000);
    expect(await this.atoken.balanceOf(this.addresses[0].address)).to.equal(11);
    expect(await this.btoken.balanceOf(this.addresses[0].address)).to.equal(500);
    expect(await this.amm.getBReserve()).to.equal(0);
    expect(await this.amm.getAReserve()).to.equal(0);

  });
});
