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
  const stakedTokenAddress = readContractAddress("/MockStakedToken.json");
  const maxTokenPerUser = constants.maxTokenPerUser;
  const startTime = Math.round(Date.now() / 1000);
  const endTime = startTime + 60 * 60 * 1000;
  const ipfsId = "QmUhzdNsJTVdgRaQrPjufvxSiyWCoesk8L8BamyzaeQXwz";

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
    ipfsId
  );
  await publicSale.deployed();

  console.log("Token address of publicSale:", publicSale.address);

  saveFrontendFiles(publicSale, "PublicSale");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
