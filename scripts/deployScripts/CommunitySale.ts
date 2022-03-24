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
    const maxTokenPerUser = constants.maxTokenPerUser;
    const startTime = Math.round(Date.now() / 1000);
    const endTime = startTime + 60 * 60 * 1000;

    const CommunitySaleFactory = await ethers.getContractFactory("CommunitySale");
    const communitySale = await CommunitySaleFactory.deploy(
        mockProjectToken,
        mockStableCoin,
        price,
        totalAmountToRaise,
        totalSupply,
        maxTokenPerUser,
        startTime,
        endTime,
        ""
    );
    await communitySale.deployed();

    console.log("Token address of communitySale:", communitySale.address);

    saveFrontendFiles(communitySale, "CommunitySale");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
