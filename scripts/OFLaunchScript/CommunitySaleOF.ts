import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { readContractAddress, saveFrontendFiles } from "../helpers";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../constants";

async function main() {
  const [deployer] = await ethers.getSigners();

  const mockProjectToken = readContractAddress("/MockProjectToken.json");
  const mockStableCoin = readContractAddress("/MockStableCoin.json");
  const price = constants.tokenPrice;
  const totalAmountToRaise = constants.amountToRaise;
  const totalSupply = constants.totalTokenSupply;
  const maxTokenPerUser = "100000000000000000000";
  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 1000;

  const CommunitySaleOF = await ethers.getContractFactory("CommunitySaleOF");
  const communitySaleOF = await CommunitySaleOF.deploy(
    mockProjectToken,
    mockStableCoin,
    price,
    totalAmountToRaise,
    totalSupply,
    maxTokenPerUser,
    startTime,
    endTime
  );
  await communitySaleOF.deployed();

  console.log("Token address of communitySaleOF:", communitySaleOF.address);

  saveFrontendFiles(communitySaleOF, "CommunitySaleOF");

  const projectTokenFact = await ethers.getContractFactory("MockProjectToken");
  const projectToken = await projectTokenFact.attach(mockProjectToken);

  await projectToken.mint(deployer.address, constants.totalTokenSupply);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
