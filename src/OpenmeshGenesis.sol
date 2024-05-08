// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOpenmeshGenesis} from "./IOpenmeshGenesis.sol";
import {IERC721Mintable} from "../lib/validator-pass/src/IERC721Mintable.sol";

import {MerkleProof} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {OpenmeshENSReverseClaimable} from "../lib/openmesh-admin/src/OpenmeshENSReverseClaimable.sol";

contract OpenmeshGenesis is OpenmeshENSReverseClaimable, IOpenmeshGenesis {
    using SafeERC20 for IERC20;

    mapping(address account => bool contributed) public hasContributed;
    uint256 public mintCount;

    IERC721Mintable public immutable validatorPass;
    PricePeriod[] public pricePeriods;
    uint32 public immutable publicMintTime;
    bytes32 public immutable whitelistRoot;

    constructor(
        IERC721Mintable _validatorPass,
        PricePeriod[] memory _pricePeriods,
        uint32 _publicMintTime,
        bytes32 _whitelistRoot
    ) {
        validatorPass = _validatorPass;
        pricePeriods = _pricePeriods;
        publicMintTime = _publicMintTime;
        whitelistRoot = _whitelistRoot;
    }

    /// @inheritdoc IOpenmeshGenesis
    function getCurrentPrice() public view returns (uint256 currentPrice) {
        for (uint256 i; i < pricePeriods.length;) {
            // Find first period with current mintCount under the period mintCount
            if (mintCount < pricePeriods[i].mintCount) {
                return pricePeriods[i].price;
            }

            unchecked {
                ++i;
            }
        }

        revert MintOver();
    }

    /// @inheritdoc IOpenmeshGenesis
    function canPublicMint(address _account) public view returns (bool allowed) {
        return !hasContributed[_account] && block.timestamp > publicMintTime;
    }

    /// @inheritdoc IOpenmeshGenesis
    function canWhitelistMint(address _account, bytes32[] memory _proof, uint32 _mintTime)
        public
        view
        returns (bool allowed)
    {
        return !hasContributed[_account] && block.timestamp > _mintTime && _verifyWhitelist(_proof, _account, _mintTime);
    }

    /// @inheritdoc IOpenmeshGenesis
    function publicMint() external payable {
        if (!canPublicMint(msg.sender)) {
            revert NotAllowed();
        }

        _mint();
    }

    /// @inheritdoc IOpenmeshGenesis
    function whitelistMint(bytes32[] memory _proof, uint32 _mintTime) external payable {
        if (!canWhitelistMint(msg.sender, _proof, _mintTime)) {
            revert NotAllowed();
        }

        _mint();
    }

    /// @inheritdoc IOpenmeshGenesis
    function collectFunds() external {
        // Send all native currency of this contract to treasury
        (bool success,) = OPENMESH_ADMIN.call{value: address(this).balance}("");
        if (!success) {
            revert TransferReverted();
        }
    }

    function _mint() internal {
        uint256 price = getCurrentPrice();
        if (msg.value < price) {
            revert Underpaying(msg.value, price);
        }

        // Return any overpayment
        uint256 refund;
        unchecked {
            refund = msg.value - price;
        }
        if (refund != 0) {
            (bool success,) = msg.sender.call{value: refund}("");
            if (!success) {
                revert TransferReverted();
            }
        }

        validatorPass.mint(msg.sender);
        unchecked {
            // Mint count is capped by price period
            ++mintCount;
        }

        hasContributed[msg.sender] = true;
        emit Mint(msg.sender, price);
    }

    function _verifyWhitelist(bytes32[] memory _proof, address _account, uint32 _mintTime)
        internal
        view
        returns (bool valid)
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _mintTime))));
        return MerkleProof.verify(_proof, whitelistRoot, leaf);
    }

    /// @notice To save any erc20 funds stuck in this contract
    function rescue(IERC20 _token, address _to, uint256 _amount) external {
        if (msg.sender != OPENMESH_ADMIN) {
            revert NotAllowed();
        }

        _token.safeTransfer(_to, _amount);
    }
}
