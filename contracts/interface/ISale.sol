pragma solidity ^0.8.0;

interface ISale {
    function changeContractStatus(bool status) external;

    function setNftAddress(address nftTokenAddress_) external returns(address);

    function setStakedTokenAddress(address stakeTokenAddress_) external returns(address);

    function withdrawRemainingTokens(address to_) external returns(uint256);

    function withdrawRaisedAmount() external returns(uint256);
}
