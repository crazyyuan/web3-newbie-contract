import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Web3WomenNewbie", function () {
  const baseURI = "https://api-preview.frenart.io/member/governance/metaData/";

  async function deployFixture() {
    const [owner, member] = await ethers.getSigners();

    const factory = await ethers.getContractFactory("Web3WomenNewbie");
    const contract = await factory.deploy(baseURI);

    return {
      contract,
      owner,
      member,
    };
  }

  it("#1 - Should set the right owner", async function () {
    const { contract, owner } = await loadFixture(deployFixture);
    expect(await contract.owner()).to.equal(owner.address);
  });

  it("#2 - Mint", async function () {
    const { contract, owner, member } = await loadFixture(deployFixture);
    await contract.connect(member).mint();
    console.log("member nft:", await contract.balanceOf(member.address));
  });
});
