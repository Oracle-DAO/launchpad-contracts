// @ts-ignore
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { saveFrontendFiles } from "../helpers";

async function main() {
  const MockStakedTokenFact = await ethers.getContractFactory(
    "MockStakedToken"
  );
  const mockStakedToken = await MockStakedTokenFact.deploy();
  await mockStakedToken.deployed();

  console.log("Token address of mockStakedToken:", mockStakedToken.address);

  saveFrontendFiles(mockStakedToken, "MockStakedToken");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
