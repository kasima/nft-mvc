import { expect } from "chai";
import hre from "hardhat";


describe("NFTMVC", function() {
  describe("constructor()", async function() {
    it("mints the specified number of NFTs", async function() {
      
    });
  });

  describe("balanceOf()", async function() {
    it("returns the number of NFTs owned by an address", async function() {
    });
  });

  describe("ownerOf()", async function() {
    it("returns the owner address of a tokenID", async function() {
    });
  });

  describe("transferFrom()", async function() {
    it("changes the owner of a tokenID if called by the current owner", async function() {
    });
    it("emits a Transfer event", async function() {
    });

    it("does not change the owner if not called by owner, approved, or operator", async function() {
    })
  });

  describe("approve()", async function() {
    it("allows transferFrom for an approved address", async function() {
    });
    it("emits an Approve event", async function() {
    });

    it("does not approve if not called by the owner", async function() {
    });
  });

  describe("setApprovalForAll()", async function() {
    it("allows transferFrom for all tokens owned by caller for operator addresses", async function() {
    });
    it("emits an ApproveForAll event", async function() {
    });

    it("does not approve for tokens not owned by caller", async function() {
    });
  });

  describe("getApproved()", async function() {
    it("returns the approved address of a tokenID", async function() {
    });
  });

  describe("isApprovedForAll()", async function() {
    it("returns True if given operator is approved for owner's tokens", async function() {
    });
  });
});