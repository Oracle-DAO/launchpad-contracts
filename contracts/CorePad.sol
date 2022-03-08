//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IERC20.sol";
import "./interface/ISale.sol";

import "hardhat/console.sol";
import "./PublicSale.sol";
import "./PrivateSale.sol";
import "./CommunitySale.sol";

contract CorePad is Ownable {

    using FixedPoint for *;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for uint32;

    enum SaleType {
        PUBLIC,
        PRIVATE,
        COMMUNITY
    }

    struct RateInfo {
        uint32 ratePercent;
    }

    struct AdminInfo {
        address admin;
    }

    struct TokenInfo {
        uint256 totalTokenSupply;
        uint256 price;
        uint256 maxTokenPerUser;
    }

    struct TokenVestingInfo {
        uint32 vestingTerm;
        uint32 lockingTerm;
    }

    struct AmountVestingInfo {
        uint32 vestingTerm;
        uint32 lockingTerm;
    }

    struct ProjectSaleTime {
        uint32 startTimestamp;
        uint32 endTimestamp;
    }

    struct ProjectInfo {
        string ipfsId;
        address projectToken;
        address principalToken;
        uint256 totalAmountToRaise;
        TokenInfo tokenInfo;
        SaleType saleType;
        ProjectSaleTime projectSaleTime;
        address admin;
        bool isValue;
//        TokenVestingInfo tokenVestingInfo;
//        AmountVestingInfo amountVestingInfo;
//        bool lock;
    }

    mapping(uint32 => ProjectInfo) public projectInfoMapping;
    uint256 constant public PRICE_DECIMALS = 1e18;

    uint32 private projectId;
    mapping(uint32 => address) private projectMapping;
    mapping(uint32 => uint32) private projectToRateMapping;

    address private _stakedTokenAddress;
    address private _nftAddressForPrivateSale;
    address private _ecosystemManager;

    uint256 private _totalPlatformFee;

    constructor (address stakedTokenAddress_) {
        require(stakedTokenAddress_ != address(0));
        _stakedTokenAddress = stakedTokenAddress_;
        projectId = 0;
    }

    function setNFTAddress(address nftAddress_) external onlyOwner {
        require(nftAddress_ != address(0));
        _nftAddressForPrivateSale = nftAddress_;
    }

    function addProject(SaleType saleType_,
        address projectTokenAddress_,
        address principalToken_,
        address adminAddress_,
        address projectSaleContractAddress_)
    external onlyOwner returns(uint32) {
        require(projectTokenAddress_ != address(0));
        require(principalToken_ != address(0));
        require(adminAddress_ != address(0));
        require(projectSaleContractAddress_ != address(0));
        projectId += 1;

        ProjectInfo memory projectInfo;

        projectInfo.projectToken = projectTokenAddress_;
        projectInfo.principalToken = principalToken_;
        projectInfo.admin = adminAddress_;
        projectInfo.saleType = saleType_;
        projectInfo.isValue = true;

        projectMapping[projectId] = projectSaleContractAddress_;
        projectInfoMapping[projectId] = projectInfo;
        return projectId;
    }

    function addProjectMetaData(
        uint32 projectId_,
        uint32 startTime_,
        uint32 endTime_,
        uint256 amountToRaise_,
        uint256 price_,
        uint256 maxTokenPerUser_,
        uint256 tokenTotalSupply_) external onlyOwner {
        require(projectInfoMapping[projectId_].isValue, "Project Id invalid");
        require(startTime_ < block.timestamp, "Invalid start time");
        require(endTime_ > startTime_, "Invalid end timestamp");
        require(endTime_ > block.timestamp, "Invalid End timestamp");
        require(amountToRaise_ > 0);
        require(price_ > 0);

        projectInfoMapping[projectId_].projectSaleTime = ProjectSaleTime({
            startTimestamp: startTime_,
            endTimestamp: endTime_
        });

        projectInfoMapping[projectId_].tokenInfo = TokenInfo({
            totalTokenSupply: tokenTotalSupply_,
            price: price_,
            maxTokenPerUser: maxTokenPerUser_
        });

        projectInfoMapping[projectId_].totalAmountToRaise = amountToRaise_;
    }

    function getProjectContractAddress(uint8 projectId_) external view returns (address) {
        require(projectId_ <= projectId, "Invalid ProjectId");
        return projectMapping[projectId_];
    }

    function setRateInfo(uint8 projectId_, uint32 ratePercent_) external onlyOwner {
        require(projectId_ <= projectId, "Invalid ProjectId");
        projectToRateMapping[projectId_] = ratePercent_;
    }

    function withdrawRaisedAmount(uint8 projectId_) external onlyOwner {
        require(projectId_ <= projectId, "Invalid ProjectId");
        address saleContract = projectMapping[projectId_];
        uint256 totalRaisedAmount = ISale(saleContract).withdrawRaisedAmount();

        uint32 ratePercent =  projectToRateMapping[projectId_];
        uint256 platformFee = totalRaisedAmount.mul(ratePercent).div(1e5);
        uint256 payoutAmount = totalRaisedAmount.sub(ratePercent);

        _totalPlatformFee += platformFee;

        ProjectInfo memory projectInfo = projectInfoMapping[projectId_];
        IERC20(projectInfo.principalToken).transfer(_ecosystemManager, platformFee);

        IERC20(projectInfo.principalToken).transfer(projectInfo.admin, payoutAmount);
    }

    function getTotalPlatformFee() external view onlyOwner returns(uint256) {
        return _totalPlatformFee;
    }

    function getProjectId() external view returns(uint256) {
        return projectId;
    }

    function getStakedAddress() external view returns(address) {
        return _stakedTokenAddress;
    }

    function getNFTAddressForPrivateSale() external view returns(address) {
        return _nftAddressForPrivateSale;
    }

    function getEcosystemManager() external view returns(address) {
        return _ecosystemManager;
    }

}
