import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { readContractAddress, saveFrontendFiles } from "../helpers";

async function main() {
  const mockStakedAddress = readContractAddress("/MockStakedToken.json");

  const CorePadFactory = await ethers.getContractFactory("CorePad");
  const corePad = await CorePadFactory.deploy(mockStakedAddress);
  await corePad.deployed();

  console.log("Token address of corePad:", corePad.address);

  saveFrontendFiles(corePad, "CorePad");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
