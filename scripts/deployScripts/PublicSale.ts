// @ts-ignore
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { readContractAddress, saveFrontendFiles } from "../helpers";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../constants";

async function main() {
  const mockProjectToken = readContractAddress("/MockProjectToken.json");
  const mockStableCoin = readContractAddress("/MockStableCoin.json");
  const price = constants.tokenPrice;
  const totalAmountToRaise = constants.amountToRaise;
  const totalSupply = constants.totalTokenSupply;
  // const stakedTokenAddress = readContractAddress("/MockStakedToken.json");
  const stakedTokenAddress = "0x4FDcdBC13285E82d7F472Bf3E87b1a0D89be6738";
  const maxTokenPerUser = constants.maxTokenPerUser;
  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 1000;

  const PublicSaleFactory = await ethers.getContractFactory("PublicSale");
  const publicSale = await PublicSaleFactory.deploy(
    mockProjectToken,
    mockStableCoin,
    price,
    totalAmountToRaise,
    totalSupply,
    stakedTokenAddress,
    maxTokenPerUser,
    startTime,
    endTime,
      "QmUhzdNsJTVdgRaQrPjufvxSiyWCoesk8L8BamyzaeQXwz"
  );
  await publicSale.deployed();

  console.log("Token address of publicSale:", publicSale.address);

  saveFrontendFiles(publicSale, "PublicSale");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
