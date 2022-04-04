import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("Private Sale Contract", async () => {
  let projectToken: Contract,
    stableCoin: Contract,
    nft: Contract,
    deployer: any,
    corePad: any,
    user1: any,
    user2: any,
    user3: any,
    admin1: any,
    privateSale: Contract,
    nftAlter: any;

  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 5;

  before(async () => {
    [deployer, corePad, user1, user2, user3, admin1, nftAlter] =
      await ethers.getSigners();

    const projectTokenFact = await ethers.getContractFactory(
      "MockProjectToken"
    );
    projectToken = await projectTokenFact.deploy();
    const stableCoinFact = await ethers.getContractFactory("MockStableCoin");
    stableCoin = await stableCoinFact.deploy();
    const mockNftFact = await ethers.getContractFactory("MockNft");
    nft = await mockNftFact.deploy("");

    const privateSaleFact = await ethers.getContractFactory("PrivateSale");
    privateSale = await privateSaleFact.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.amountToRaise,
      constants.totalTokenSupply,
      nft.address,
      constants.maxTokenPerUser,
      startTime,
      endTime,
      ""
    );

    await privateSale.initialize(corePad.address, admin1.address);
  });

  it("Check initialized", async function () {
    expect(await privateSale.owner()).to.equal(corePad.address);
    expect(await privateSale.admin()).to.equal(admin1.address);
  });

  it("Check contract status", async function () {
    await expect(privateSale.changeContractStatus(false)).to.be.revertedWith(
      "Caller Invalid"
    );

    await privateSale.connect(corePad).changeContractStatus(false);

    await expect(await privateSale.contractStatus()).to.equal(false);
  });

  it("Check Nft Address", async function () {
    await expect(await privateSale.getNFTAddress()).to.equal(
      nft.address
    );

    await expect(
      privateSale.setNftAddress(nftAlter.address)
    ).to.be.revertedWith("Caller not owner");

    await privateSale.connect(corePad)
      .setNftAddress(nftAlter.address);

    await expect(await privateSale.getNFTAddress()).to.equal(
        nftAlter.address
    );
  });

  it("Check Participate reverts", async function () {
    await expect(
      privateSale
        .connect(user1)
        .participate(user1.address, "1000000000000000000")
    ).to.be.revertedWith("Sale Contract is Inactive");

    await privateSale.connect(corePad).changeContractStatus(true);

    await expect(
      privateSale.connect(user1).participate(user1.address, 0)
    ).to.be.revertedWith("invalid amount");

    await privateSale.connect(corePad).setTimeInfo(startTime + 60 * 60, 0);

    await expect(
      privateSale
        .connect(user1)
        .participate(user1.address, "1000000000000000000")
    ).to.be.revertedWith("project not live");

    await privateSale.connect(corePad).setTimeInfo(startTime, startTime);

    await expect(
      privateSale
        .connect(user1)
        .participate(user1.address, "1000000000000000000")
    ).to.be.revertedWith("project has ended");
  });

  it("Check Participate for Users", async function () {
    await privateSale.connect(corePad).setNftAddress(nft.address);
    await privateSale.connect(corePad).setTimeInfo(startTime, endTime);
    await projectToken.mint(privateSale.address, constants.totalTokenSupply);

    await nft.mint(user1.address);
    await nft.mint(user2.address);
    await nft.mint(user3.address);

    await stableCoin.mint(user1.address, "10000000000000000000");
    await stableCoin.mint(user2.address, "10000000000000000000");
    await stableCoin.mint(user3.address, "10000000000000000000");

    await stableCoin
      .connect(user1)
      .approve(privateSale.address, constants.largeApproval);
    await stableCoin
      .connect(user2)
      .approve(privateSale.address, constants.largeApproval);
    await stableCoin
      .connect(user3)
      .approve(privateSale.address, constants.largeApproval);

    await privateSale
      .connect(user1)
      .participate(user1.address, "1000000000000000000");
    await privateSale
      .connect(user2)
      .participate(user2.address, "1000000000000000000");
    await privateSale
      .connect(user3)
      .participate(user3.address, "1000000000000000000");
  });
});
