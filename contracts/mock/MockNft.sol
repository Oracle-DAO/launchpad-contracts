// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockNft is Ownable, ERC721 {

    using SafeMath for uint256;
    string private baseURI;
    uint256 private currentTokenId;

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    constructor(string memory baseURI_) ERC721('MockStable', 'MS') {
        baseURI = baseURI_;
        currentTokenId = 1;
        _mint(msg.sender, currentTokenId);
    }

    function mint(address to) external {
        currentTokenId++;
        _mint(to, currentTokenId);
    }
}
