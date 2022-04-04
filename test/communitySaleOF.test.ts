import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
describe("OF Community Sale Contract", async () => {
  let projectToken: Contract,
    stableCoin: Contract,
    deployer: SignerWithAddress,
    corePad: SignerWithAddress,
    user1: SignerWithAddress,
    user2: SignerWithAddress,
    user3: SignerWithAddress,
    admin1: SignerWithAddress,
    whitelistSigningKey: SignerWithAddress,
    communitySaleOF: Contract;

  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 5;

  before(async () => {
    [deployer, corePad, user1, user2, user3, admin1] =
      await ethers.getSigners();

    const projectTokenFact = await ethers.getContractFactory(
      "MockProjectToken"
    );
    projectToken = await projectTokenFact.deploy();
    const stableCoinFact = await ethers.getContractFactory("MockStableCoin");
    stableCoin = await stableCoinFact.deploy();

    const CommunitySaleOF = await ethers.getContractFactory("CommunitySaleOF");
    communitySaleOF = await CommunitySaleOF.deploy(
      projectToken.address,
      stableCoin.address,
      constants.tokenPrice,
      constants.amountToRaise,
      constants.totalTokenSupply,
      constants.maxTokenPerUser,
      startTime,
      endTime
    );
  });

  it("Check initialized", async function () {
    expect(await communitySaleOF.owner()).to.equal(deployer.address);
  });

  it("Whitelist and address and Check Participate reverts", async function () {

  });
});
