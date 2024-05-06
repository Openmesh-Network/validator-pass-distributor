// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOpenmeshGenesis} from "./IOpenmeshGenesis.sol";
import {IERC721Mintable} from "../lib/validator-pass/src/IERC721Mintable.sol";

import {MerkleProof} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import {OpenmeshENSReverseClaimable} from "../lib/openmesh-admin/src/OpenmeshENSReverseClaimable.sol";

contract OpenmeshGenesis is OpenmeshENSReverseClaimable, IOpenmeshGenesis {
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
    function publicMint() external {
        if (!canPublicMint(msg.sender)) {
            revert NotAllowed();
        }

        _mint();
    }

    /// @inheritdoc IOpenmeshGenesis
    function whitelistMint(bytes32[] memory _proof, uint32 _mintTime) external {
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

        validatorPass.mint(msg.sender);

        hasContributed[msg.sender] = true;
        emit Mint(msg.sender, msg.value);
    }

    function _verifyWhitelist(bytes32[] memory _proof, address _account, uint32 _mintTime)
        internal
        view
        returns (bool valid)
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account, _mintTime))));
        return MerkleProof.verify(_proof, whitelistRoot, leaf);
    }
}
