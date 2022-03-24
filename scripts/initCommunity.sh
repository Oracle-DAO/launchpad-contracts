#!/bin/bash

npx hardhat run ./deployScripts/MockProjectToken.ts --network oasis &&
npx hardhat run ./deployScripts/CommunitySale.ts --network oasis &&
npx hardhat run ./deployScripts/addCommunitySale.ts --network oasis