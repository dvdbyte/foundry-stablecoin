// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author dvdbyte
 *
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1$ peg
 * This stablecoin has the following properties:
 * -Exogenous Collateral
 * -Dollar Pegged
 * -Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC
 *
 * Our DSC System should always be "Overcollateralized" At no point, should the value of all collateral <= the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the system. It handles all the logic for minting and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice this contract is VERY loosely based on the MakerDao DSS (DAI) system
 */

contract DSCEngine is ReentrancyGuard {
    error DCCEngine__NeedsMoreThanZero();
    error DCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DCCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    

    mapping(address token => address priceFeeds) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    event CollateralDeposited(address indexed user, address indexed token,  uint256 indexed amount);

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DCCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DCCEngine__NotAllowedToken();
        }
        _;
    }

    /*
     * @param tokenCollateralAddress
     * @param amountCollateral
     */

    function depositCollateralAndMintDsc() external {}

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool succes= IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!succes) {
          revert DSCEngine__TransferFailed();
        }


    }

  
    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    //1. Check if the collateral value > DSC amount 
    /* @notice follows CEI
     * @param amountDscToMint The amount of decentralized stablecoin to mint
     * @notice they must have collateral value than the minimum threshold
     */

    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint)nonReentrant {
      s_DSCMinted[msg.sender] += amountDscToMint;
      // If they minted too much
      _revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ///////////////////////////////////////////
    //// Private & Internal view Functions ////
    ////////////////////////////////////////// 

    function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 collateralValueInUsd){
        totalDscMinted=s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
     * Retturns how close to liquidation a user is 
     * If a user goes below 1, then they can get liquidated
     * 
     */
    function _healthFactor(address user) internal view returns(uint256) {

      (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);


    }

    function  _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Chech health factor (do they have enough collateral?)
        // 2. Revert if they don't
     }

    ///////////////////////////////////////////
    ///// Public& External view Functions /////
    ///////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256  totalCollateraValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++){

          address token = s_collateralTokens[i];
          uint256 amount = s_collateralDeposited[user][token];
          totalCollateraValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateraValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return ((uint256(answer) * ADDITIONAL_FEED_PRECISION) * amount) / 1e18;
      }
}
