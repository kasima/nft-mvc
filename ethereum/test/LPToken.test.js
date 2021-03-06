const { expect } = require("chai");

const TOKEN_NAME = "AMMMVC LP";
const TOKEN_SYMBOL = "AMMMVC-LP";

describe("LPToken", function () {
  beforeEach(async function () {
    [this.owner, this.alice] = await ethers.getSigners();
    const LPtoken = await ethers.getContractFactory("LPToken");
    this.lptoken = await LPtoken.deploy(TOKEN_NAME, TOKEN_SYMBOL);
    await this.lptoken.deployed();
  })

  it("should return the correct name and symbol", async function () {
    expect(await this.lptoken.name()).to.be.equal(TOKEN_NAME);
    expect(await this.lptoken.symbol()).to.be.equal(TOKEN_SYMBOL);
  });

  it("should only be mintable by owner", async function () {
    await this.lptoken.mint(this.owner.address, 1000); // returns no exception
    await expect(this.lptoken.connect(this.alice).mint(this.owner.address, 1000)).to.be.revertedWith("Ownable: caller is not the owner");
  })

  it("should only be burnable by owner", async function () {
    await this.lptoken.mint(this.owner.address, 1000); // returns no exception
    await this.lptoken.burn(1000); // returns no exception
    await expect(this.lptoken.connect(this.alice).burn(1000)).to.be.revertedWith("Ownable: caller is not the owner");
  })
})
