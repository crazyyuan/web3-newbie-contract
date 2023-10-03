import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { keccak256 } from "@ethersproject/keccak256";
import { MerkleTree } from "merkletreejs";

describe("Web3WomenNewbie", function () {
  const baseURI =
    "ipfs://bafybeihylw5ehx5tm636pzfm3crrxrlf56i6avxvvmsbrpnx4vyaisdz54/";

  async function deployFixture() {
    const [owner, member, user1, user2, user3] = await ethers.getSigners();

    const factory = await ethers.getContractFactory("Web3WomenNewbieD4");
    const contract = await factory.deploy(baseURI, 5);

    return {
      contract,
      owner,
      member,
      user1,
      user2,
      user3,
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

    await contract.connect(owner).setStatus(1);

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

  it("#3 - Airdrop", async function () {
    const { contract, owner, member, user1 } = await loadFixture(deployFixture);

    await contract.connect(owner).setStatus(1);

    await contract.connect(owner).airdrop([member.address, user1.address]);
  });

  it("#4 - Allow list mint", async function () {
    const { contract, owner, user1, user2, user3 } = await loadFixture(
      deployFixture
    );

    await contract.connect(owner).setStatus(3);

    const leaves = [user1.address, user2.address, user3.address].map((addr) =>
      keccak256(addr)
    );
    const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const root = merkleTree.getRoot();

    await contract.connect(owner).setMerkleRoot(root);

    const amountIn = ethers.utils.parseEther("0.0005");
    const proof = merkleTree.getHexProof(keccak256(user1.address));
    await contract.connect(user1).allowlistMint2(proof, { value: amountIn });
  });

  it("#5 - Allow list mint", async function () {
    const { contract, owner, user1, user2, user3 } = await loadFixture(
      deployFixture
    );

    await contract.connect(owner).setStatus(3);

    await contract
      .connect(owner)
      .setAllowList([user1.address, user2.address, user3.address]);

    const amountIn = ethers.utils.parseEther("0.0005");

    await contract.connect(user1).allowlistMint({ value: amountIn });

    await contract.connect(owner).setAllowList([user1.address, user2.address]);

    await contract.connect(user2).allowlistMint({ value: amountIn });
  });
});
