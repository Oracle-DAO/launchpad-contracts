#!/bin/bash

npx hardhat run ./deployScripts/MockProjectToken.ts --network oasis &&
npx  hardhat run ./deployScripts/MockStableCoin.ts --network oasis &&
npx hardhat run ./deployScripts/MockStakedToken.ts --network oasis &&
npx hardhat run ./deployScripts/CorePad.ts --network oasis &&
npx hardhat run ./deployScripts/PublicSale.ts --network oasis &&
npx hardhat run ./deployScripts/initialize.ts --network oasis