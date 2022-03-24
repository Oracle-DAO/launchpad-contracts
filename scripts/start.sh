#!/bin/bash

npx hardhat run ./deployScripts/MockStableCoin.ts --network oasis &&
npx hardhat run ./deployScripts/CorePad.ts --network oasis