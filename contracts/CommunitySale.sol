// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";

import "./library/LowGasSafeMath.sol";
import "./library/SafeERC20.sol";
import "./EIP712Whitelisting.sol";

contract CommunitySale is EIP712Whitelisting {

    using SafeERC20 for IERC20;
    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    mapping(address => uint256) public userToTokenAmount;

    uint256 public totalTokenSupply;
    uint256 public totalAmountRaised;
    uint256 public totalAmountToRaise;
    uint256 public price;
    uint32 public totalParticipatedUser;
    uint32 public startTimestamp;
    uint32 public endTimestamp;
    uint256 public maxTokenPerUser;
    bool public contractStatus;
    string ipfsId;

    IERC20 private projectToken;
    IERC20 private principalToken;
    address private _admin;
    address private _owner;

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
        uint256 maxTokenPerUser_,
        uint32 startTime_,
        uint32 endTime_,
        string memory ipfsId_) EIP712Whitelisting()
    {
        _owner = msg.sender;
        projectToken = IERC20(tokenAdd_);
        principalToken = IERC20(principal_);
        price = price_;
        totalAmountToRaise = totalAmountToRaise_;
        totalTokenSupply = totalTokenSupply_;
        maxTokenPerUser = maxTokenPerUser_;
        startTimestamp = startTime_;
        endTimestamp = endTime_;
        ipfsId = ipfsId_;
    }

    function initialize(address owner_, address admin_) external {
        require(owner_ != address(0));
        require(admin_ != address(0));
        _owner = owner_;
        _admin = admin_;
    }

    receive() external payable{
    }

    // ============= Owner/Admin Actions =================

    function changeContractStatus(bool status) external onlyCaller {
        contractStatus = status;
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

    function setTimeInfo(uint32 startTime_, uint32 endTime_) external onlyCaller {
        require(startTime_ != 0 || endTime_ != 0, "Both timestamp cannot be 0");
        if(startTime_ != 0){
            startTimestamp = startTime_;
        }
        if(endTime_!= 0){
            endTimestamp = endTime_;
        }
    }

    // ============= User Actions =================

    // don't forget to approve the principal token
    function participate(uint256 amount_, bytes calldata signature) external requiresWhitelist(signature) {
        require(contractStatus, "Sale Contract is Inactive");
        require(amount_ > 0, "invalid amount");
        require(startTimestamp < block.timestamp, "project not live");
        require(endTimestamp > block.timestamp, "project has ended");
        require(totalAmountRaised.add(amount_) <= totalAmountToRaise, "Amount exceeds total amount to raise");
        uint256 value = payoutFor(amount_);
        require(userToTokenAmount[msg.sender].add(value) <= maxTokenPerUser, "Token amount exceed");
        if(userToTokenAmount[msg.sender]  == 0){
            totalParticipatedUser += 1;
        }

        totalAmountRaised += amount_;
        userToTokenAmount[msg.sender] = userToTokenAmount[msg.sender].add(value);
        principalToken.safeTransferFrom(msg.sender, address(this), amount_);
        projectToken.safeTransfer(msg.sender, value);
    }


    // ============= GETTER =================
    function payoutFor(uint256 amount) public view returns(uint256){
        return ((FixedPoint.fraction(amount, price).decode112with18()).div(1e15)).mul(1e15);
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

    function getIpfsId() external view returns(string memory){
        return ipfsId;
    }

    function getProjectDetails() external view returns(
        address projectToken_,
        address principalToken_,
        string memory ipfsId_,
        bool contractStatus_
    ){
        principalToken_ = address(principalToken);
        projectToken_ = address(projectToken);
        ipfsId_ = ipfsId;
        contractStatus_ = contractStatus;
    }

    function getTokenInfo() external view returns(
        uint256 totalTokenSupply_,
        address projectToken_,
        uint256 tokenPrice_
    ){
        totalTokenSupply_ = totalTokenSupply;
        projectToken_ = address(projectToken);
        tokenPrice_ = price;
    }

    function getAmountInfo() external view returns(
        uint256 totalAmountToRaise_,
        uint256 totalAmountRaised_
    ) {
        totalAmountRaised_ = totalAmountRaised;
        totalAmountToRaise_ = totalAmountToRaise;
    }

    function getProjectTimeInfo() external view returns(
        uint32 startTimestamp_,
        uint32 endTimestamp_
    ){
        startTimestamp_ = startTimestamp;
        endTimestamp_ = endTimestamp;
    }
}
