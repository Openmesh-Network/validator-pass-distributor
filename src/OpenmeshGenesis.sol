// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOpenmeshGenesis} from "./IOpenmeshGenesis.sol";
import {IERC20MintBurnable} from "../lib/open-token/src/IERC20MintBurnable.sol";
import {IERC721Mintable} from "../lib/validator-pass/src/IERC721Mintable.sol";

import {OpenmeshENSReverseClaimable} from "../lib/openmesh-admin/src/OpenmeshENSReverseClaimable.sol";

contract OpenmeshGenesis is OpenmeshENSReverseClaimable, IOpenmeshGenesis {
    mapping(address => uint256) public contributed;
    uint256[] public tokensPerWeiPerPeriod;
    IERC20MintBurnable public immutable token;
    IERC721Mintable public immutable nft;
    uint32 public immutable start;
    uint32[] public periodEnds;
    uint256 public immutable minWeiPerAccount;
    uint256 public immutable maxWeiPerAccount;

    constructor(
        uint256[] memory _tokensPerWeiPerPeriod,
        IERC20MintBurnable _token,
        IERC721Mintable _nft,
        uint32 _start,
        uint32[] memory _periodEnds,
        uint256 _minWeiPerAccount,
        uint256 _maxWeiPerAccount
    ) {
        tokensPerWeiPerPeriod = _tokensPerWeiPerPeriod;
        token = _token;
        nft = _nft;
        start = _start;
        periodEnds = _periodEnds;
        minWeiPerAccount = _minWeiPerAccount;
        maxWeiPerAccount = _maxWeiPerAccount;
    }

    fallback() external payable {
        _fundraise();
    }

    receive() external payable {
        _fundraise();
    }

    /// @inheritdoc IOpenmeshGenesis
    function tokensPerWei() public view returns (uint256) {
        if (block.timestamp < start) {
            revert NotDuringFundraisingPeriod();
        }

        for (uint256 periodIndex; periodIndex < periodEnds.length;) {
            // Find first period with block.timestamp earlier than that period end
            if (block.timestamp < periodEnds[periodIndex]) {
                return tokensPerWeiPerPeriod[periodIndex];
            }

            unchecked {
                ++periodIndex;
            }
        }

        revert NotDuringFundraisingPeriod();
    }

    function _fundraise() internal {
        if (msg.value == 0) {
            revert NoFundsAttached();
        }

        uint256 personalContribution = contributed[msg.sender] + msg.value;
        if (personalContribution < minWeiPerAccount) {
            revert LessThanMinPerAccount();
        }
        if (personalContribution > maxWeiPerAccount) {
            revert SurpassMaxPerAccount();
        }

        uint256 giveTokens = msg.value * tokensPerWei();
        bool giveNFT = personalContribution == maxWeiPerAccount;

        token.transfer(msg.sender, giveTokens);
        if (giveNFT) {
            nft.mint(msg.sender);
        }

        contributed[msg.sender] = personalContribution;
        emit ContributionMade(msg.sender, msg.value, giveTokens, giveNFT);
    }

    /// @inheritdoc IOpenmeshGenesis
    function collectContributions() external {
        if (block.timestamp < periodEnds[periodEnds.length - 1]) {
            revert FundraiserNotOverYet();
        }

        // Send all native currency of this contract to treasury
        (bool success,) = OPENMESH_ADMIN.call{value: address(this).balance}("");
        if (!success) {
            revert TreasuryReverted();
        }

        // Burn remaining tokens
        token.burn(token.balanceOf(address(this)));
    }
}
