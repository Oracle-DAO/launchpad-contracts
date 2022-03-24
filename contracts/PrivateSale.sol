// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./library/FixedPoint.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
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
    uint256 public maxTokenPerUser;
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
        uint256 maxTokenPerUser_,
        uint32 startTime_,
        uint32 endTime_,
        string memory ipfsId_)
    {
        _owner = msg.sender;
        projectToken = IERC20(tokenAdd_);
        principalToken = IERC20(principal_);
        price = price_;
        totalAmountToRaise = totalAmountToRaise_;
        totalTokenSupply = totalTokenSupply_;
        maxTokenPerUser = maxTokenPerUser_;
        nftAddress = nftAddress_;
        startTimestamp = startTime_;
        endTimestamp = endTime_;
        ipfsId = ipfsId_;
        contractStatus = true;
    }

    function initialize(address owner_, address admin_) external {
        require(owner_ != address(0));
        require(admin_ != address(0));
        _owner = owner_;
        _admin = admin_;
    }

    // ============= Owner/Admin Actions =================

    function changeContractStatus(bool status) external onlyCaller {
        contractStatus = status;
    }

    function setNftAddress(address nftTokenAddress_) external returns(address) {
        require(msg.sender == _owner, "Caller not owner");
        require(nftTokenAddress_ != address(0));
        nftAddress = nftTokenAddress_;
        return nftAddress;
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

    receive() external payable {
    }

    // don't forget to approve the principal token
    function participate(address to_, uint256 amount) external {
        require(contractStatus, "Sale Contract is Inactive");
        require(amount > 0, "invalid amount");
        require(startTimestamp < block.timestamp, "project not live");
        require(endTimestamp > block.timestamp, "project has ended");
        require(totalAmountRaised.add(amount) <= totalAmountToRaise, "Amount exceeds total amount to raise");
        uint256 value = payoutFor(amount);
        require(userToTokenAmount[msg.sender].add(value) <= maxTokenPerUser, "Token amount exceed");
        isAllowedParticipation(to_);
        if(userToTokenAmount[to_]  == 0){
            totalParticipatedUser += 1;
        }

        totalAmountRaised += amount;
        userToTokenAmount[to_] = userToTokenAmount[to_].add(value);
        principalToken.safeTransferFrom(msg.sender, address(this), amount);
        projectToken.safeTransfer(to_, value);
    }

    function isAllowedParticipation(address to_) internal view {
        require(IERC721(nftAddress).balanceOf(to_) > 0, "No Nft present for the user");
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
