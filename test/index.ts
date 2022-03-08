import { expect } from "chai";
import { ethers } from "hardhat";
import { constants } from "./constants";

describe("Public Sale", function () {
  it("Deploy Sale Contract", async function () {
    const [deployer] = await ethers.getSigners();

    const MockProjectToken = await ethers.getContractFactory(
      "MockProjectToken"
    );
    const projectToken = await MockProjectToken.deploy();
    await projectToken.deployed();

    const MockStableCoin = await ethers.getContractFactory("MockStableCoin");
    const stableCoin = await MockStableCoin.deploy();
    await stableCoin.deployed();

    const MockStakedToken = await ethers.getContractFactory("MockStakedToken");
    const stakedToken = await MockStakedToken.deploy();
    await stakedToken.deployed();

    const startTime = Math.round(Date.now() / 1000);
    const endTime = startTime + 60 * 60 * 5;

    const PublicSale = await ethers.getContractFactory("PublicSale");
    const publicSale = await PublicSale.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.totalTokenSupply,
      stakedToken.address,
      constants.maxTokenPerUser,
      startTime,
      endTime
    );
    await publicSale.deployed();

    const CorePad = await ethers.getContractFactory("CorePad");
    const corePad = await CorePad.deploy(stakedToken.address);
    await corePad.deployed();

    expect(await corePad.getStakedAddress()).to.equal(stakedToken.address);
  });
});
