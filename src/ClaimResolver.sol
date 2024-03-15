// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/ISBCDepositContract.sol";
import "./interfaces/IRegistry.sol";

contract ClaimResolver {
    uint256 public batchSize;
    uint256 public offset;

    ISBCDepositContract public depositContract;
    IRegistry public registry;

    event ClaimBatch(address indexed caller, address[] users);

    constructor(ISBCDepositContract _depositContract, IRegistry _registry, uint256 _batchSize) {
        depositContract = ISBCDepositContract(_depositContract);
        registry = IRegistry(_registry);
        batchSize = _batchSize;
        offset = 0;
    }

    function cliamBatch(address[] calldata users, uint256 newOffset) public {
        depositContract.claimWithdrawals(users);
        registry.updateLastClaim(users);
        offset = newOffset;
        emit ClaimBatch(msg.sender, users);
    }

    function resolve() public view returns (bool flag, bytes memory cdata) {
        address[] memory addresses;

        (addresses, newOffset) = registry.getClaimableAddresses(offset, batchSize);

        return (true, abi.encodeWithSelector(this.cliamBatch.selector, addresses, newOffset));
    }
}
