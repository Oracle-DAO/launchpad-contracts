import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("Core Pad", async () => {
  let projectToken: Contract,
    stableCoin: Contract,
    stakedToken: Contract,
    corePad: Contract,
    deployer: any,
    user1: any,
    user2: any,
    admin1: any,
    admin2: any,
    nftAddress: any,
    ecosystemAddress: any,
    project1: Contract,
    project2: Contract;

  // const currentBlock = await ethers.provider.getBlock("latest");
  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 5;

  before(async () => {
    [deployer, user1, user2, admin1, admin2, nftAddress, ecosystemAddress] =
      await ethers.getSigners();

    const projectTokenFact = await ethers.getContractFactory(
      "MockProjectToken"
    );
    projectToken = await projectTokenFact.deploy();
    const stableCoinFact = await ethers.getContractFactory("MockStableCoin");
    stableCoin = await stableCoinFact.deploy();
    const stakedTokenFact = await ethers.getContractFactory("MockStakedToken");
    stakedToken = await stakedTokenFact.deploy();

    const CorePad = await ethers.getContractFactory("CorePad");
    corePad = await CorePad.deploy(stakedToken.address);
    await corePad.deployed();

    const project1Fact = await ethers.getContractFactory("PublicSale");
    const project2Fact = await ethers.getContractFactory("PublicSale");

    project1 = await project1Fact.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.amountToRaise,
      constants.totalTokenSupply,
      stakedToken.address,
      constants.maxTokenPerUser,
      startTime,
      endTime,
      ""
    );
    project2 = await project2Fact.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.amountToRaise,
      constants.totalTokenSupply,
      stakedToken.address,
      constants.maxTokenPerUser,
      startTime,
      endTime,
      ""
    );
  });

  it("Check Staked Address", async function () {
    expect(await corePad.getStakedAddress()).to.equal(stakedToken.address);
  });

  it("Check NFT Address", async function () {
    await corePad.setNFTAddress(nftAddress.address);

    expect(await corePad.getNFTAddressForPrivateSale()).to.equal(
      nftAddress.address
    );
  });

  it("Check ecosystem Address", async function () {
    await corePad.setEcosystemManager(ecosystemAddress.address);

    expect(await corePad.getEcosystemManager()).to.equal(
      ecosystemAddress.address
    );
  });

  it("Check Add Project and Meta Details", async function () {
    project1.initialize(corePad.address, admin1.address);
    project2.initialize(corePad.address, admin2.address);

    await corePad.addProject(
      0,
      projectToken.address,
      stableCoin.address,
      admin1.address,
      project1.address
    );

    expect(await corePad.getProjectId()).to.equal(1);
    expect(await corePad.getProjectContractAddress(1)).to.equal(
      project1.address
    );

    await corePad.addProject(
      0,
      projectToken.address,
      stableCoin.address,
      admin2.address,
      project2.address
    );

    expect(await corePad.getProjectId()).to.equal(2);
    expect(await corePad.getProjectContractAddress(2)).to.equal(
      project2.address
    );

    await corePad.addProjectMetaData(
      1,
      startTime,
      endTime,
      constants.amountToRaise,
      constants.tokenPrice,
      constants.maxTokenPerUser,
      constants.totalTokenSupply,
      ""
    );
    //
    const projectInfo = await corePad.projectInfoMapping(1);
    expect(projectInfo.admin).to.equal(admin1.address);
    expect(projectInfo.totalAmountToRaise).to.equal(constants.amountToRaise);
    expect(projectInfo.tokenInfo.totalTokenSupply).to.equal(
      constants.totalTokenSupply
    );
    expect(projectInfo.tokenInfo.price).to.equal(constants.tokenPrice);

    const projectInfo2 = await corePad.projectInfoMapping(2);
    expect(projectInfo2.admin).to.equal(admin2.address);
  });

  it("Check RateInfo", async function () {
    await corePad.setRateInfo(1, 5000);

    expect(await corePad.getRateInfoForProject(1)).to.equal(5000);
    expect(await corePad.getRateInfoForProject(2)).to.equal(0);
    await expect(corePad.setRateInfo(3, 5000)).to.be.revertedWith(
      "Invalid ProjectId"
    );
  });

  it("Withdraw Raised Amount", async function () {
    await stableCoin.mint(user1.address, "5000000000000000000");
    await stableCoin.mint(user2.address, "5000000000000000000");

    await stakedToken.mint(user1.address, "5000000000000000000");
    await stakedToken.mint(user2.address, "5000000000000000000");

    await stableCoin
      .connect(user1)
      .approve(project1.address, constants.largeApproval);
    await stableCoin
      .connect(user2)
      .approve(project1.address, constants.largeApproval);

    await projectToken.mint(project1.address, constants.totalTokenSupply);
    await project1
      .connect(user1)
      .participate(user1.address, "500000000000000000");

    await project1
      .connect(user2)
      .participate(user2.address, "500000000000000000");

    expect(await projectToken.balanceOf(user1.address)).to.equal(
      "500000000000000000"
    );

    expect(await projectToken.balanceOf(user2.address)).to.equal(
      "500000000000000000"
    );
    expect(await project1.totalParticipatedUser()).to.equal(2);
    expect(await project1.totalAmountRaised()).to.equal("1000000000000000000");

    expect(await stableCoin.balanceOf(project1.address)).to.equal(
      "1000000000000000000"
    );

    expect(await corePad.getRateInfoForProject(1)).to.equal(5000);
    await corePad.withdrawRaisedAmount(1);

    expect(await corePad.getTotalPlatformFee()).to.equal("50000000000000000");
  });
});
