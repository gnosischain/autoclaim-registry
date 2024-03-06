 // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IDeposit} from "./interfaces/ISBCDepostContract.sol";

contract ClaimRegistry {
    struct Config {
        uint256 lastClaim;
        uint256 minClaimDelay;
        uint256 minAmount;
    }

    ISBCDepostContract public deposit;
    mapping(address => Config) public configs;

    constructor(ISBCDepostContract _deposit) {
        deposit = _deposit;
    }

    function setConfig(uint256 minClaimDelay, uint256 minAmount) public {
        configs[msg.sender].minClaimDelay = minClaimDelay;
        configs[msg.sender].minAmount = minAmount;
    }

    function claim(address user) public {
        Config memory config = configs[user];
        require(config.minClaimDelay > 0, "NOT_ENABLED");

        // Check delay
        if (block.timestamp - config.lastClaim < config.minClaimDelay) {
            return;
        }

        // Check amount
        uint256 balance = deposit.withdrawableAmount(user);
        if (balance < config.minAmount) {
            return;
        }

        // Do the claim
        try deposit.claimWithdrawals(user) {
            configs[user].lastClaim = block.timestamp;
        } catch {}
    }

    function batchClaim(address[] calldata users) public {
        uint256 length = users.length;

        for (uint256 i = 0; i < length; ) {
            claim(users[i]);

            unchecked {
                i++;
            }
        }
    }
}