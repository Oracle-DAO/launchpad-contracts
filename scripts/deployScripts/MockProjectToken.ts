// @ts-ignore
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { saveFrontendFiles } from "../helpers";

async function main() {
  const MockProjectTokenFact = await ethers.getContractFactory(
    "MockProjectToken"
  );
  const mockProjectToken = await MockProjectTokenFact.deploy();
  await mockProjectToken.deployed();

  console.log("Token address of mockProjectToken:", mockProjectToken.address);

  saveFrontendFiles(mockProjectToken, "MockProjectToken");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
