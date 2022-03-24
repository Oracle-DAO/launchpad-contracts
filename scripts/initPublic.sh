#!/bin/bash

npx hardhat run ./deployScripts/MockStakedToken.ts --network oasis &&
npx hardhat run ./deployScripts/MockProjectToken.ts --network oasis &&
npx hardhat run ./deployScripts/PublicSale.ts --network oasis &&
npx hardhat run ./deployScripts/addPublicSale.ts --network oasis