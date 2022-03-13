#!/bin/bash

npx hardhat run ./deployScripts/MockProjectToken.ts --network localhost &&
npx hardhat run ./deployScripts/MockStableCoin.ts --network localhost &&
npx hardhat run ./deployScripts/MockStakedToken.ts --network localhost &&
npx hardhat run ./deployScripts/CorePad.ts --network localhost &&
npx hardhat run ./deployScripts/PublicSale.ts --network localhost &&
npx hardhat run ./deployScripts/initialize.ts --network localhost