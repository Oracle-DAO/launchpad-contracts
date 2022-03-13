// @ts-ignore
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { saveFrontendFiles } from "../helpers";

async function main() {
  const MockStableCoinFact = await ethers.getContractFactory("MockStableCoin");
  const mockStableCoin = await MockStableCoinFact.deploy();
  await mockStableCoin.deployed();

  console.log("Token address of mockStableCoin:", mockStableCoin.address);

  saveFrontendFiles(mockStableCoin, "MockStableCoin");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
