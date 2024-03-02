// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenmeshGenesis {
    error NoFundsAttached();
    error LessThanMinPerAccount();
    error SurpassMaxPerAccount();

    error TreasuryReverted();

    error NotDuringFundraisingPeriod();
    error FundraiserNotOverYet();

    event ContributionMade(address from, uint256 amount, uint256 givenTokens, bool givenNFT);

    /// Returns the current rate (amount of tokens received per wei of native currency contributed).
    function tokensPerWei() external view returns (uint256);

    /// Sends all native currency stored in this contract to the DAO treasury.
    /// @dev Can only be called after the event is over. Any remaining tokens that the contract has will be burned.
    function collectContributions() external;
}
