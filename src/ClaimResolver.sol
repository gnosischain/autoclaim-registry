// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/ISBCDepositContract.sol";
import "./Registry.sol";


contract ClaimResolver {

    uint256 public batchSize;
    uint256 public offset;

    ISBCDepositContract public depositContract;
    Registry public registry;

    event ClaimBatch(address indexed caller, address[] users);

    // TODO:
    constructor(ISBCDepositContract _depositContract, Registry _registry, uint256 _batchSize) {
        depositContract = _depositContract;
        registry = _registry;
        batchSize = _batchSize;
        offset = 0;
    }

    function cliamBatch(address[] calldata users) public {
        depositContract.claimWithdrawals(users);
        _shiftOffset();
        ClaimBatch(msg.sender, users);
    }

    // TOOD:
    function _shiftOffset() internal {
        if offset + batchSize >= registry.getValidatorsLength()) {
            offset = 0;
        } else {
            offset += batchSize;
        }
    }

    function resolve() public view returns (bool flag, bytes memory cdata) {
        address[] memory addresses = registry.getClaimableAddresses(offset, batchSize);
        return (true, abi.encodeWithSelector(this.claimBatch.selector, addresses));
    }
}