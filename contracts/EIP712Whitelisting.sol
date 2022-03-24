//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Whitelisting {
    using ECDSA for bytes32;
    address private _owner;

    // The key used to sign whitelist signatures.
    address private _whitelistSigningKey = address(0);

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant MINTER_TYPEHASH =
    keccak256("WhitelistedStruct(address walletAddress)");

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
            // This should match the domain you set in your client side signing.
                keccak256(bytes("WhitelistAddress")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        _owner = msg.sender;
    }

    function setWhitelistSigningAddress(address newSigningKey) public {
        require(msg.sender == _owner);
        _whitelistSigningKey = newSigningKey;
    }

    modifier requiresWhitelist(bytes calldata signature) {
        require(_whitelistSigningKey != address(0), "whitelist not enabled");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );

        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == _whitelistSigningKey, "Invalid Signature");
        _;
    }

    function whitelistSigningKey() external returns(address){
        require(msg.sender == _owner, "Caller not Owner");
        return _whitelistSigningKey;
    }
}
