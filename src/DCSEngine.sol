// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

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

contract DSCEngine {
  function depositCollateralAndMintDsc() external {}

  function depositCollateral() external {}

  function redeemCollateralForDsc() external {}

  function redeemCollateral() external {}

  funtion mintDsc() external {}

  function burnDsc() external {}

  function liquidate() external {}

  function getHealthFactor() external view {}

}