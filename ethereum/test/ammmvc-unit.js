const { expect } = require("chai");

describe("AmmMVC", function() {
  it("swap", async function() {
    // A_pool = 10
    // B_pool = 500
    // invariant = 10 * 500 = 5000

    const addresses = await ethers.getSigners()
    const Token = await ethers.getContractFactory("Token");
    const atoken = await Token.deploy("tokenA", "A");
    const btoken = await Token.deploy("tokenB", "B");
    await atoken.deployed();
    await btoken.deployed();
    const Amm = await ethers.getContractFactory("AmmMVC");
    const amm = await Amm.deploy(atoken.address, btoken.address, "AB Token LP", "LP-AB");
    await amm.deployed();
    const lpAddress = await amm.lpTokenAddress();
    const lptoken = await ethers.getContractAt("Token", lpAddress);
    await atoken.mint(addresses[0].address, 11);
    await btoken.mint(addresses[0].address, 500);
    await atoken.approve(amm.address, 11);
    await btoken.approve(amm.address, 500);
    await amm.addLiquidity(10, 500);
    expect(await lptoken.balanceOf(addresses[0].address)).to.equal(5000);
    expect(await amm.getAReserve()).to.equal(10);
    expect(await amm.getBReserve()).to.equal(500);

    // Buyer sends: 1 A
    // A_pool = 10 + 1 = 11
    // B_pool = 5000/11 = 454
    // Buyer receieves: 500 - 454 = 46 B

    expect(await amm.getAtoBOutput(1)).to.equal(46);
    await amm.swapAtoB(1);
    expect(await amm.getBReserve()).to.equal(454);
    expect(await amm.getAReserve()).to.equal(11);

    await lptoken.approve(amm.address, 5000);
    await amm.removeLiquidity(5000);
    expect(await atoken.balanceOf(addresses[0].address)).to.equal(11);
    expect(await btoken.balanceOf(addresses[0].address)).to.equal(500);
    expect(await amm.getBReserve()).to.equal(0);
    expect(await amm.getAReserve()).to.equal(0);

  });
});
