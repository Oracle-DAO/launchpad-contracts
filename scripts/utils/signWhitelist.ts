import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export default async function signWhitelist(
  chainId: number,
  contractAddress: string,
  whitelistKey: SignerWithAddress,
  mintingAddress: string
) {

  const domain = {
    name: "WhitelistAddress",
    version: "1",
    chainId,
    verifyingContract: contractAddress,
  };

  const types = {
    WhitelistedStruct: [{ name: "walletAddress", type: "address" }],
  };

  return await whitelistKey._signTypedData(domain, types, {
    walletAddress: mintingAddress,
  });
}
