#!/bin/bash

npx hardhat run ./deployScripts/MockNft.ts --network oasis &&
npx hardhat run ./deployScripts/MockProjectToken.ts --network oasis &&
npx hardhat run ./deployScripts/PrivateSale.ts --network oasis &&
npx hardhat run ./deployScripts/addPrivateSale.ts --network oasis