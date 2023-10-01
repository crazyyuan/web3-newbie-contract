import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Web3WomenNewbie", function () {
  const baseURI =
    "ipfs://bafybeihylw5ehx5tm636pzfm3crrxrlf56i6avxvvmsbrpnx4vyaisdz54/";

  async function deployFixture() {
    const [owner, member] = await ethers.getSigners();

    const factory = await ethers.getContractFactory("Web3WomenNewbie");
    const contract = await factory.deploy(baseURI, 5);

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

    const balanceBefore = await ethers.provider.getBalance(contract.address);

    const amountIn = ethers.utils.parseEther("0.001");

    await contract.connect(member).mint({ value: amountIn });

    expect(await contract.balanceOf(member.address)).to.be.equal(1);
    expect(
      (await ethers.provider.getBalance(contract.address))._hex
    ).to.be.equal(balanceBefore.add(amountIn)._hex);

    await contract.connect(member).mint({ value: amountIn });
    await contract.connect(member).mint({ value: amountIn });
    await contract.connect(member).mint({ value: amountIn });
    await contract.connect(member).mint({ value: amountIn });
  });
});
