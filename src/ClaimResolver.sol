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

    function cliamBatch(address[] calldata users, uint256 newOffset) public {
        depositContract.claimWithdrawals(users);
        offset = newOffset;
        emit ClaimBatch(msg.sender, users);
    }



    function resolve() public view returns (bool flag, bytes memory cdata) {
        uint256 offsetMem = offset;
        address[] memory addresses;

        while (addresses.length == 0) {
            (addresses, offsetMem) = registry.getClaimableAddresses(offsetMem, batchSize);
            if (offsetMem + batchSize >= registry.getValidatorsLength()) {
                offsetMem = 0;
            } else {
                offsetMem += batchSize;
            }
        }

        return (true, abi.encodeWithSelector(this.cliamBatch.selector, addresses, offsetMem));
    }
}