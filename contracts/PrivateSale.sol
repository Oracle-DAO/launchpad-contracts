pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
        uint32 projectId_,
        address tokenAdd_,
        address principal_,
        address admin_,
        uint256 price_,
        uint256 totalTokenSupply_,
        address nftAddress_,
        uint256 maxTokenPerUser_,
        uint32 startTime_,
        uint32 endTime_)
    {
        _owner = msg.sender;
        require(projectId > 0);
        projectId = projectId;
        projectToken = IERC20(tokenAdd_);
        principalToken = IERC20(principal_);
        _admin = admin_;
        price = price_;
        totalTokenSupply = totalTokenSupply_;
        nftAddress = nftAddress_;
        startTimestamp = startTime_;
        endTimestamp = endTime_;
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

    function payoutFor(uint256 amount) internal returns(uint256){
        return FixedPoint.fraction(amount, price).decode112with18();
    }
}
