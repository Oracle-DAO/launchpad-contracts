pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./library/LowGasSafeMath.sol";
import "./library/SafeERC20.sol";

contract CommunitySale {

    using SafeERC20 for IERC20;
    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    uint32 public projectId;
    mapping(address => uint256) public userToTokenAmount;
    mapping(address => uint8) public whiteListedUser;
    uint256 public totalTokenSupply;
    uint256 public totalAmountRaised;
    uint256 public totalAmountToRaise;
    uint256 public price;
    uint32 public totalParticipatedUser;
    uint32 public startTimestamp;
    uint32 public endTimestamp;
    uint256 public maxTokenPerUser;
    bool public contractStatus;

    IERC20 private projectToken;
    IERC20 private principalToken;
    address private _admin;
    address private _owner;
    address private stakedTokenAddress; // Token address which user need to stake for access
    uint256 private fee;

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
        address stakedTokenAddress_,
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
        stakedTokenAddress = stakedTokenAddress_;
        maxTokenPerUser = maxTokenPerUser_;
        startTimestamp = startTime_;
        endTimestamp = endTime_;
    }

    receive() external payable{
    }

    // ============= Owner/Admin Actions =================

    function changeContractStatus(bool status) external onlyCaller {
        contractStatus = status;
    }

    function setCommunityFee(uint256 fee_) external onlyCaller {
        require(fee < 5000, "Fee cannot be greater than 5%");
        fee = fee_;
    }

    function setStakedTokenAddress(address stakeTokenAddress_) external returns(address) {
        require(msg.sender == _owner, "Invalid User");
        require(stakeTokenAddress_ != address(0));
        stakedTokenAddress = stakeTokenAddress_;
        return stakedTokenAddress;
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

    function _whitelistUser(address to_) internal {
        whiteListedUser[to_] = 1;
    }

    function removeWhitelistedUser(address to_) external onlyCaller {
        whiteListedUser[to_] = 0;
    }

    function whitelistUser(address to_) external onlyCaller {
        _whitelistUser(to_);
    }

    function whiteListUsers(address[] calldata userList) external onlyCaller {
        for(uint32 i=0; i<userList.length; i++){
            _whitelistUser(userList[i]);
        }
    }

    // ============= User Actions =================

    // don't forget to approve the principal token
    function participate(address to_, uint256 amount) external {
        require(amount > 0, "invalid amount");
        require(startTimestamp < block.timestamp, "project not live");
        require(endTimestamp > block.timestamp, "project has ended");
        require(totalAmountRaised.add(amount) > totalAmountToRaise, "Amount exceeds total amount to raise");
        uint256 platformFee = amount.mul(fee).div(1e5);
        uint256 payoutAmount = amount.sub(platformFee);
        uint256 value = payoutFor(payoutAmount);
        require(userToTokenAmount[to_].add(value) < maxTokenPerUser, "Token amount for user exceed");

        if(userToTokenAmount[to_]  == 0){
            totalParticipatedUser += 1;
        }

        // platform fee for community member
        principalToken.safeTransferFrom(msg.sender, _owner, platformFee);

        totalAmountRaised += payoutAmount;
        userToTokenAmount[to_] = userToTokenAmount[to_].add(value);

        principalToken.safeTransferFrom(to_, address(this), payoutAmount);
        projectToken.safeTransfer(to_, value);
    }


    function payoutFor(uint256 amount) internal returns(uint256){
        return FixedPoint.fraction(amount, price).decode112with18();
    }
}
