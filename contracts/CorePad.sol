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

    struct ProjectInfo {
        uint32 projectId;
        string ipfsId;
        address projectToken;
        address principalToken;
        uint32 startTimestamp;
        uint32 endTimestamp;
//        uint256 totalAmountRaised;
        uint256 totalAmountToRaise;
        TokenInfo tokenInfo;
        SaleType saleType;
        address admin;
//        TokenVestingInfo tokenVestingInfo;
//        AmountVestingInfo amountVestingInfo;
//        bool lock;
    }

    mapping(uint32 => ProjectInfo) public projectInfoMapping;
    uint256 constant public PRICE_DECIMALS = 1e18;

    uint32 private _projectId;
    mapping(uint32 => address) private projectMapping;
    mapping(uint32 => uint32) private projectToRateMapping;

    address private stakedTokenAddress;
    address private nftAddressForPrivateSale;
    address private ecosystemManager;

    uint256 private _totalPlatformFee;

    constructor (address stakedTokenAddress_) {
        require(stakedTokenAddress != address(0));
        stakedTokenAddress = stakedTokenAddress_;
        _projectId = 0;
    }

    function setNFTAddress(address _nftAddress) external onlyOwner {
        require(_nftAddress != address(0));
        nftAddressForPrivateSale = _nftAddress;
    }

    function addProject(
        string memory ipfsId_,
        address projectTokenAdd_,
        address principalToken_,
        address adminAddress_,
        uint32 startTime_,
        uint32 endTime_,
        uint256 amountToRaise_,
        uint256 price_,
        uint256 maxTokenPerUser_,
        uint256 tokenTotalSupply_,
        SaleType saleType
    ) external onlyOwner returns(uint32) {
        _projectId += 1;
        require(projectTokenAdd_ != address(0));
        require(principalToken_ != address(0));
        require(adminAddress_ != address(0));
        require(startTime_ < block.timestamp, "Invalid start time");
        require(adminAddress_ != address(0), "admin address empty");
        require(endTime_ > startTime_, "Invalid end timestamp");
        require(
            endTime_ > block.timestamp, "Invalid End timestamp");
        require(amountToRaise_ > 0);
        require(price_ > 0);

        address contractAdd;

        TokenInfo memory tokenInfo = TokenInfo({
            totalTokenSupply: tokenTotalSupply_,
            price: price_,
            maxTokenPerUser: maxTokenPerUser_
        });


        projectInfoMapping[_projectId] = ProjectInfo({
            projectId: _projectId,
            projectToken: projectTokenAdd_,
            ipfsId: ipfsId_,
            principalToken: principalToken_,
            startTimestamp: startTime_,
            endTimestamp: endTime_,
            totalAmountToRaise: amountToRaise_,
            tokenInfo: tokenInfo,
            saleType: saleType,
            admin: adminAddress_
        });

        if(saleType == SaleType.COMMUNITY){
            CommunitySale communitySale = new CommunitySale(_projectId, projectTokenAdd_, principalToken_, adminAddress_,
                price_, tokenTotalSupply_, stakedTokenAddress, maxTokenPerUser_, startTime_, endTime_);
            projectMapping[_projectId] = address(communitySale);
        }
        else if(saleType == SaleType.PRIVATE){
            PrivateSale privateSale = new PrivateSale(_projectId, projectTokenAdd_, principalToken_, adminAddress_,
                price_, tokenTotalSupply_, nftAddressForPrivateSale, maxTokenPerUser_, startTime_, endTime_);
            projectMapping[_projectId] = address(privateSale);
        }
        else{
            PublicSale publicSale = new PublicSale(_projectId, projectTokenAdd_, principalToken_, adminAddress_,
                price_, tokenTotalSupply_, stakedTokenAddress, maxTokenPerUser_, startTime_, endTime_);
            projectMapping[_projectId] = address(publicSale);
        }
        return _projectId;
    }

    function getProjectContractAddress(uint8 projectId_) external view returns (address) {
        require(projectId_ <= _projectId, "Invalid ProjectId");
        return projectMapping[projectId_];
    }

    function setRateInfo(uint8 projectId_, uint32 ratePercent_) external onlyOwner {
        require(projectId_ <= _projectId, "Invalid ProjectId");
        projectToRateMapping[projectId_] = ratePercent_;
    }

    function withdrawRaisedAmount(uint8 projectId_) external onlyOwner {
        require(projectId_ <= _projectId, "Invalid ProjectId");
        address saleContract = projectMapping[projectId_];
        uint256 totalRaisedAmount = ISale(saleContract).withdrawRaisedAmount();

        uint32 ratePercent =  projectToRateMapping[projectId_];
        uint256 platformFee = totalRaisedAmount.mul(ratePercent).div(1e5);
        uint256 payoutAmount = totalRaisedAmount.sub(ratePercent);

        _totalPlatformFee += platformFee;

        ProjectInfo memory projectInfo = projectInfoMapping[projectId_];
        IERC20(projectInfo.principalToken).transfer(ecosystemManager, platformFee);

        IERC20(projectInfo.principalToken).transfer(projectInfo.admin, payoutAmount);
    }

    function getTotalPlatformFee() external view onlyOwner returns(uint256) {
        return _totalPlatformFee;
    }

    function projectId() external view returns(uint256) {
        return _projectId;
    }

}
