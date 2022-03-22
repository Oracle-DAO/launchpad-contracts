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
    const nftAddress = readContractAddress("/MockNft.json");
    const maxTokenPerUser = constants.maxTokenPerUser;
    const startTime = Math.round(Date.now() / 1000);
    const endTime = startTime + 60 * 60 * 1000;

    const PrivateSaleFactory = await ethers.getContractFactory("PrivateSale");
    const privateSale = await PrivateSaleFactory.deploy(
        mockProjectToken,
        mockStableCoin,
        price,
        totalAmountToRaise,
        totalSupply,
        nftAddress,
        startTime,
        endTime,
        ""
    );
    await privateSale.deployed();

    console.log("Token address of privateSale:", privateSale.address);

    saveFrontendFiles(privateSale, "PrivateSale");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
