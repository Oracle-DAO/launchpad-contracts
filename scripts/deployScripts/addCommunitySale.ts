import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { readContractAddress } from "../helpers";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../constants";
const corePadAdd = readContractAddress("/CorePad.json");
const communitySaleAdd = readContractAddress("/CommunitySale.json");
const mockProjectTokenAdd = readContractAddress("/MockProjectToken.json");
const mockStableCoinAdd = readContractAddress("/MockStableCoin.json");
const mockStakedTokenAdd = readContractAddress("/MockStakedToken.json");

async function main() {
    const [deployer, admin, whitelistSigningKey] = await ethers.getSigners();

    const projectTokenFact = await ethers.getContractFactory("MockProjectToken");
    const projectToken = await projectTokenFact.attach(mockProjectTokenAdd);
    const stableCoinFact = await ethers.getContractFactory("MockStableCoin");
    const stableCoin = await stableCoinFact.attach(mockStableCoinAdd);

    const communitySaleFact = await ethers.getContractFactory("CommunitySale");
    const communitySale = communitySaleFact.attach(communitySaleAdd);

    const CorePadFact = await ethers.getContractFactory("CorePad");
    const corePad = CorePadFact.attach(corePadAdd);

    const startTime = await communitySale.startTimestamp();
    const endTime = await communitySale.endTimestamp();

    await communitySale.setWhitelistSigningAddress(whitelistSigningKey.address);
    await communitySale.initialize(corePad.address, admin.address);

    await corePad.addProject(
        0,
        projectToken.address,
        stableCoin.address,
        admin.address,
        communitySale.address
    );

    await corePad.addProjectMetaData(
        1,
        startTime,
        endTime,
        constants.amountToRaise,
        constants.tokenPrice,
        constants.maxTokenPerUser,
        constants.totalTokenSupply,
        ""
    );

    await projectToken.mint(deployer.address, constants.totalTokenSupply);

    console.log("Contracts has been initialized");
    console.log("Contract Address of MockStableCoin", mockStableCoinAdd);
    console.log("Contract Address of MockStakedToken", mockStakedTokenAdd);
    console.log("Contract Address of MockProjectToken", mockProjectTokenAdd);
    console.log("Contract Address of CorePad", corePadAdd);
    console.log("Contract Address of Community Sale", communitySaleAdd);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
