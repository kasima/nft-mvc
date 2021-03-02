const { expect } = require("chai");

describe("AmmMVC", function() {
  it("swap", async function() {
    // A_pool = 10
    // B_pool = 500
    // invariant = 10 * 500 = 5000

    const Token = await ethers.getContractFactory("Token");
    const atoken = await Token.deploy("tokenA", "A");
    const btoken = await Token.deploy("tokenB", "B");
    await atoken.deployed();
    await btoken.deployed();
    const Amm = await ethers.getContractFactory("AmmMVC");
    const amm = await Amm.deploy(atoken.address, btoken.address);
    await amm.deployed();
    await atoken.mint(11);
    await btoken.mint(500);
    await atoken.approve(amm.address, 11);
    await btoken.approve(amm.address, 500);
    await amm.setAReserve(10);
    await amm.setBReserve(500);
    expect(await amm.getAReserve()).to.equal(10);
    expect(await amm.getBReserve()).to.equal(500);

    // Buyer sends: 1 A
    // A_pool = 10 + 1 = 11
    // B_pool = 5000/11 = 454
    // Buyer receieves: 500 - 454 = 46 B

    expect(await amm.getAtoBOutput(1)).to.equal(46);
    await amm.swapAtoB(1);
    expect(await amm.getBReserve()).to.equal(454);
  });
});
