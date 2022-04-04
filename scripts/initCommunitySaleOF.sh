#!/bin/bash

npx hardhat run ./OFLaunchScript/CommunitySaleOF.ts --network localhost &&
npx hardhat run ./OFLaunchScript/whitelistUsers.ts --network localhost