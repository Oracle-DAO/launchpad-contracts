import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("Public Sale Contract", async () => {
  let projectToken: Contract,
    stableCoin: Contract,
    stakedToken: Contract,
    deployer: any,
    corePad: any,
    user1: any,
    user2: any,
    user3: any,
    admin1: any,
    publicSale: Contract,
    stakedTokenAlter: any;

  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 5;

  before(async () => {
    [deployer, corePad, user1, user2, user3, admin1, stakedTokenAlter] =
      await ethers.getSigners();

    const projectTokenFact = await ethers.getContractFactory(
      "MockProjectToken"
    );
    projectToken = await projectTokenFact.deploy();
    const stableCoinFact = await ethers.getContractFactory("MockStableCoin");
    stableCoin = await stableCoinFact.deploy();
    const stakedTokenFact = await ethers.getContractFactory("MockStakedToken");
    stakedToken = await stakedTokenFact.deploy();

    const publicSaleFact = await ethers.getContractFactory("PublicSale");

    publicSale = await publicSaleFact.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.totalTokenSupply,
      stakedToken.address,
      constants.maxTokenPerUser,
      startTime,
      endTime
    );

    await publicSale.initialize(corePad.address, admin1.address);
  });

  it("Check initialized", async function () {
    expect(await publicSale.owner()).to.equal(corePad.address);
    expect(await publicSale.admin()).to.equal(admin1.address);
  });

  it("Check contract status", async function () {
    await expect(publicSale.changeContractStatus(false)).to.be.revertedWith(
      "Caller Invalid"
    );

    await publicSale.connect(corePad).changeContractStatus(false);

    await expect(await publicSale.contractStatus()).to.equal(false);
  });

  it("Check Staked Token Address", async function () {
    await expect(await publicSale.getStakedTokenAddress()).to.equal(
      stakedToken.address
    );

    await expect(
      publicSale.setStakedTokenAddress(stakedTokenAlter.address)
    ).to.be.revertedWith("Caller not owner");

    await publicSale
      .connect(corePad)
      .setStakedTokenAddress(stakedTokenAlter.address);

    await expect(await publicSale.getStakedTokenAddress()).to.equal(
      stakedTokenAlter.address
    );
  });

  it("Check Participate reverts", async function () {
    await expect(
      publicSale
        .connect(user1)
        .participate(user1.address, "1000000000000000000")
    ).to.be.revertedWith("Sale Contract is Inactive");

    await publicSale.connect(corePad).changeContractStatus(true);

    await expect(
      publicSale.connect(user1).participate(user1.address, 0)
    ).to.be.revertedWith("invalid amount");

    await publicSale.connect(corePad).setTimeInfo(startTime + 60 * 60, 0);

    await expect(
      publicSale
        .connect(user1)
        .participate(user1.address, "1000000000000000000")
    ).to.be.revertedWith("project not live");

    await publicSale.connect(corePad).setTimeInfo(startTime, startTime);

    await expect(
      publicSale
        .connect(user1)
        .participate(user1.address, "1000000000000000000")
    ).to.be.revertedWith("project has ended");
  });

  it("Check Participate for Users", async function () {
    await publicSale
      .connect(corePad)
      .setStakedTokenAddress(stakedToken.address);

    await publicSale.connect(corePad).setTimeInfo(startTime, endTime);

    await projectToken.mint(publicSale.address, constants.totalTokenSupply);

    await stakedToken.mint(user1.address, "10000000000000000000");
    await stakedToken.mint(user2.address, "10000000000000000000");
    await stakedToken.mint(user3.address, "10000000000000000000");

    await stableCoin.mint(user1.address, "10000000000000000000");
    await stableCoin.mint(user2.address, "10000000000000000000");
    await stableCoin.mint(user3.address, "10000000000000000000");

    await stableCoin
      .connect(user1)
      .approve(publicSale.address, constants.largeApproval);
    await stableCoin
      .connect(user2)
      .approve(publicSale.address, constants.largeApproval);
    await stableCoin
      .connect(user3)
      .approve(publicSale.address, constants.largeApproval);

    await publicSale
      .connect(user1)
      .participate(user1.address, "1000000000000000000");
    await publicSale
      .connect(user2)
      .participate(user2.address, "1000000000000000000");
    await publicSale
      .connect(user3)
      .participate(user3.address, "1000000000000000000");
  });
});
