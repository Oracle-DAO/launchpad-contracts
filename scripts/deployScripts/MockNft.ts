// @ts-ignore
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { saveFrontendFiles } from "../helpers";

async function main() {
    const MockNftFact = await ethers.getContractFactory(
        "MockNft"
    );
    const mockNft = await MockNftFact.deploy("");
    await mockNft.deployed();

    console.log("Token address of mockNft:", mockNft.address);
    saveFrontendFiles(mockNft, "MockNft");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});