// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenmeshGenesis {
    error Underpaying(uint256 attached, uint256 minRequired);
    error MintOver();
    error NotAllowed();

    error TransferReverted();

    event Mint(address account, uint256 paid);

    struct PricePeriod {
        uint256 mintCount;
        uint256 price;
    }

    /// @notice Returns the current amount of native tokens that should be attached to mint.
    /// @dev This is dependent on the current mint count, which might change between submitting the transaction and it being confirmed.
    function getCurrentPrice() external view returns (uint256 currentPrice);

    /// @notice Returns if an account is currently allowed to public mint.
    /// @param _account The account to check.
    function canPublicMint(address _account) external view returns (bool allowed);

    /// @notice Returns if an account is currently allowed to whitelist mint.
    /// @param _account The account to check.
    /// @param _proof Merkle tree whitelist proof.
    /// @param _mintTime Mint time of the account in the merkle tree.
    function canWhitelistMint(address _account, bytes32[] memory _proof, uint32 _mintTime)
        external
        view
        returns (bool allowed);

    /// @notice Perform a public mint.
    /// @dev Every account can only mint once.
    function publicMint() external;

    /// @notice Perform a whitelist mint.
    /// @param _proof Merkle tree whitelist proof.
    /// @param _mintTime Mint time of the sender in the merkle tree.
    /// @dev Every account can only mint once.
    function whitelistMint(bytes32[] memory _proof, uint32 _mintTime) external;

    /// @notice Sends all native currency stored in this contract to the Openmesh treasury.
    /// @dev Can be called by anyone at any time. More gas efficient that sending the funds every mint.
    function collectFunds() external;
}
