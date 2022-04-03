import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { readContractAddress, saveFrontendFiles } from "../helpers";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../constants";

async function main() {
  const [deployer, whitelistSigningKey] = await ethers.getSigners();

  const mockProjectToken = readContractAddress("/MockProjectToken.json");
  const mockStableCoin = readContractAddress("/MockStableCoin.json");
  const price = constants.tokenPrice;
  const totalAmountToRaise = constants.amountToRaise;
  const totalSupply = constants.totalTokenSupply;
  const maxTokenPerUser = constants.maxTokenPerUser;
  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 1000;

  const PrivateSaleOF = await ethers.getContractFactory("PrivateSaleOF");
  const privateSaleOF = await PrivateSaleOF.deploy(
    mockProjectToken,
    mockStableCoin,
    price,
    totalAmountToRaise,
    totalSupply,
    maxTokenPerUser,
    startTime,
    endTime
  );
  await privateSaleOF.deployed();

  console.log("Token address of privateSaleOF:", privateSaleOF.address);

  saveFrontendFiles(privateSaleOF, "CommunitySale");

  const projectTokenFact = await ethers.getContractFactory("MockProjectToken");
  const projectToken = await projectTokenFact.attach(mockProjectToken);
  await projectToken.mint(deployer.address, constants.totalTokenSupply);

  await privateSaleOF.setWhitelistSigningAddress(whitelistSigningKey.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
