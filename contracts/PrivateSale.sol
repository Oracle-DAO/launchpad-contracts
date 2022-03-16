// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";

import "./library/LowGasSafeMath.sol";
import "./library/SafeERC20.sol";

contract PrivateSale {

    using SafeERC20 for IERC20;
    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    uint32 public projectId;
    mapping(address => uint256) public userToTokenAmount;
    uint256 public totalTokenSupply;
    uint256 public totalAmountRaised;
    uint256 public totalAmountToRaise;
    uint256 public price;
    uint32 public totalParticipatedUser;
    uint32 public startTimestamp;
    uint32 public endTimestamp;
    bool public contractStatus;
    string ipfsId;

    address private _admin;
    address private _owner;
    IERC20 private projectToken;
    IERC20 private principalToken;

    address private nftAddress; // Token address which user need to stake for access

    modifier onlyCaller() {
        require(_owner == msg.sender || _admin == msg.sender, "Caller Invalid");
        _;
    }

    constructor (
        address tokenAdd_,
        address principal_,
        uint256 price_,
        uint256 totalAmountToRaise_,
        uint256 totalTokenSupply_,
        address nftAddress_,
        uint32 startTime_,
        uint32 endTime_)
    {
        _owner = msg.sender;
        projectToken = IERC20(tokenAdd_);
        principalToken = IERC20(principal_);
        price = price_;
        totalAmountToRaise = totalAmountToRaise_;
        totalTokenSupply = totalTokenSupply_;
        nftAddress = nftAddress_;
        startTimestamp = startTime_;
        endTimestamp = endTime_;
        contractStatus = true;
    }

    function initialize(address owner_, address admin_) external {
        require(owner_ == msg.sender);
        require(admin_ == msg.sender);
        _owner = owner_;
        _admin = admin_;
    }

    // ============= Owner/Admin Actions =================

    function changeContractStatus(bool status) external onlyCaller {
        contractStatus = status;
    }

    function setNftAddress(address nftTokenAddress_) external returns(address) {
        require(msg.sender == _owner, "Invalid User");
        require(nftTokenAddress_ != address(0));
        nftAddress = nftTokenAddress_;
        return nftAddress;
    }

    function withdrawRemainingTokens(address to_) external onlyCaller returns(uint256) {
        uint256 balance = projectToken.balanceOf(address(this));
        projectToken.safeTransfer(to_, balance);
        return balance;
    }

    function withdrawRaisedAmount() external returns(uint256) {
        require(_owner == msg.sender);
        uint256 balance = projectToken.balanceOf(address(this));
        principalToken.safeTransfer(msg.sender, balance);
        return balance;
    }

    // ============= User Actions =================

    receive() external payable{
    }

    // don't forget to approve the principal token
    function participate(address to_, uint256 amount) external {
        require(contractStatus, "Sale Contract is Inactive");
        require(amount > 0, "invalid amount");
        require(startTimestamp < block.timestamp, "project not live");
        require(endTimestamp > block.timestamp, "project has ended");
        require(totalAmountRaised.add(amount) > totalAmountToRaise, "Amount exceeds total amount to raise");

        uint256 value = payoutFor(amount);
        if(userToTokenAmount[to_]  == 0){
            totalParticipatedUser += 1;
        }

        totalAmountRaised += amount;
        userToTokenAmount[to_] = userToTokenAmount[to_].add(value);
        principalToken.safeTransferFrom(to_, address(this), amount);
        projectToken.safeTransfer(to_, value);
    }

    function payoutFor(uint256 amount) internal view returns(uint256){
        return FixedPoint.fraction(amount, price).decode112with18();
    }

    function owner() external view returns(address){
        return _owner;
    }

    function admin() external view returns(address){
        return _admin;
    }

    function getProjectTokenAddress() external view returns(address){
        return address(projectToken);
    }

    function getNFTAddress() external view returns(address){
        return nftAddress;
    }

}
