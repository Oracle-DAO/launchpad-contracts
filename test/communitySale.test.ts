import { expect } from "chai";
import { ethers } from "hardhat";
import signWhitelist from "../scripts/utils/signWhitelist";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
describe("Community Sale Contract", async () => {
  let projectToken: Contract,
    stableCoin: Contract,
    deployer: SignerWithAddress,
    corePad: SignerWithAddress,
    user1: SignerWithAddress,
    user2: SignerWithAddress,
    user3: SignerWithAddress,
    admin1: SignerWithAddress,
    whitelistSigningKey: SignerWithAddress,
    communitySale: Contract,
    eip712Whitelisting: Contract;

  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 5;

  before(async () => {
    [deployer, corePad, user1, user2, user3, admin1, whitelistSigningKey] =
      await ethers.getSigners();

    const projectTokenFact = await ethers.getContractFactory(
      "MockProjectToken"
    );
    projectToken = await projectTokenFact.deploy();
    const stableCoinFact = await ethers.getContractFactory("MockStableCoin");
    stableCoin = await stableCoinFact.deploy();

    const communitySaleFact = await ethers.getContractFactory("CommunitySale");

    communitySale = await communitySaleFact.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.amountToRaise,
      constants.totalTokenSupply,
      constants.maxTokenPerUser,
      startTime,
      endTime,
        ""
    );

    await communitySale.initialize(corePad.address, admin1.address);

    await communitySale.setWhitelistSigningAddress(whitelistSigningKey.address);
  });

  it("Check initialized", async function () {
    expect(await communitySale.owner()).to.equal(corePad.address);
    expect(await communitySale.admin()).to.equal(admin1.address);
  });

  it("Check contract status", async function () {
    await expect(communitySale.changeContractStatus(false)).to.be.revertedWith(
      "Caller Invalid"
    );

    await communitySale.connect(corePad).changeContractStatus(false);

    await expect(await communitySale.contractStatus()).to.equal(false);
  });

  // it("Whitelist an address", async function () {
  //   let { chainId } = await ethers.provider.getNetwork();
  //   const sig = await signWhitelist(chainId, communitySale.address, whitelistSigningKey, user1.address)
  //   await communitySale.connect(user1).participate("100000000000000000", sig);
  // });


  it("Whitelist and address and Check Participate reverts", async function () {
    let { chainId } = await ethers.provider.getNetwork();
    const sig = await signWhitelist(chainId, communitySale.address, whitelistSigningKey, user1.address)

    await expect(
      communitySale
        .connect(user1)
        .participate("1000000000000000000", sig)
    ).to.be.revertedWith("Sale Contract is Inactive");

    await communitySale.connect(corePad).changeContractStatus(true);

    await expect(
      communitySale.connect(user1).participate(0, sig)
    ).to.be.revertedWith("invalid amount");

    await communitySale.connect(corePad).setTimeInfo(startTime + 60 * 60, 0);

    await expect(
      communitySale
        .connect(user1)
        .participate("1000000000000000000", sig)
    ).to.be.revertedWith("project not live");

    await communitySale.connect(corePad).setTimeInfo(startTime, startTime);

    await expect(
      communitySale
        .connect(user1)
        .participate("1000000000000000000", sig)
    ).to.be.revertedWith("project has ended");
  });

  it("Check Participate for Users", async function () {
    await communitySale.connect(corePad).setTimeInfo(startTime, endTime);

    await projectToken.mint(communitySale.address, constants.totalTokenSupply);

    await stableCoin.mint(user1.address, "10000000000000000000");
    await stableCoin.mint(user2.address, "10000000000000000000");
    await stableCoin.mint(user3.address, "10000000000000000000");

    await stableCoin
      .connect(user1)
      .approve(communitySale.address, constants.largeApproval);
    await stableCoin
      .connect(user2)
      .approve(communitySale.address, constants.largeApproval);
    await stableCoin
      .connect(user3)
      .approve(communitySale.address, constants.largeApproval);

    let { chainId } = await ethers.provider.getNetwork();
    const sig1 = await signWhitelist(chainId, communitySale.address, whitelistSigningKey, user1.address)
    const sig2 = await signWhitelist(chainId, communitySale.address, whitelistSigningKey, user2.address)
    const sig3 = await signWhitelist(chainId, communitySale.address, whitelistSigningKey, user3.address)

    await communitySale
      .connect(user1)
      .participate("1000000000000000000", sig1)
    await communitySale
      .connect(user2)
      .participate("1000000000000000000", sig2)
    await communitySale
      .connect(user3)
      .participate("1000000000000000000", sig3)
  });
});
