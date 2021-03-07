const { expect } = require("chai");

async function mintAndApprove(amm, atoken, btoken, aamount, bamount, from) {
  await atoken.mint(from, aamount);
  await btoken.mint(from, bamount);
  await atoken.approve(amm.address, aamount);
  await btoken.approve(amm.address, bamount);
}

describe("AMM Arbitrage Opportunity", function () {
  before(async function () {
    [this.liquidityProvider, this.trader, this.arbitrager] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("Token");
    this.weth = await Token.deploy("Wrapped ETH", "WETH");
    this.dai = await Token.deploy("DAI", "DAI");
    await this.weth.deployed();
    await this.dai.deployed();
    const Amm = await ethers.getContractFactory("AmmMVC");
    this.amm = await Amm.deploy(this.weth.address, this.dai.address, "WETH-DAI Token LP", "LP-WETH-DAI");
    await this.amm.deployed();
    const lpAddress = await this.amm.lpTokenAddress();
    this.lptoken = await ethers.getContractAt("LPToken", lpAddress);
    [this.liquidityProvider, this.trader, this.arbitrager].forEach((caller) => {
      caller.weth = this.weth.connect(caller);
      caller.dai = this.dai.connect(caller);
      caller.lptoken = this.lptoken.connect(caller);
      caller.amm = this.amm.connect(caller);
    });
  });

  it("liquidity provider deposits into WETH-DAI Pool", async function () {
    // MARKET PRICE:
    // WETH = 1000 USD
    // DAI = 1 USD
    await mintAndApprove(this.liquidityProvider.amm, this.liquidityProvider.weth, this.liquidityProvider.dai, 1000, 1000000, this.liquidityProvider.address);
    await this.liquidityProvider.amm.addLiquidity(1000, 1000000); // deposits 2,000,000 USD worth of assets
    expect(await this.lptoken.balanceOf(this.liquidityProvider.address)).to.be.equal(1000);
    expect(await this.amm.calculateAtoBOutput(1)).to.equal(1000); // 1 WETH = 1000 DAI, all is well
  });

  it("trader makes a large trade for DAI", async function () {
    await mintAndApprove(this.trader.amm, this.trader.weth, this.trader.dai, 100, 1, this.trader.address);
    await this.trader.amm.swapAtoB(100);
    expect(await this.dai.balanceOf(this.trader.address)).to.be.equal(90911); // 909 DAI per ETH, due to large trade size- the trader suffers 10% slippage
    expect(await this.amm.calculateAtoBOutput(1)).to.equal(826); // now 1 ETH is worth 826 DAI
  });

  it("arbitrager makes an arbitrage trade", async function () {
    await mintAndApprove(this.arbitrager.amm, this.arbitrager.weth, this.arbitrager.dai, 1, 100000, this.arbitrager.address);
    await this.arbitrager.amm.swapBtoA(100000);
    expect(await this.weth.balanceOf(this.arbitrager.address)).to.be.equal(111); // arbitrager got 1 WETH for 900 DAI, made 11000 DAI in profit
    expect(await this.amm.calculateAtoBOutput(1)).to.equal(1019); // now 1 ETH is worth 1019 DAI
  });
});
