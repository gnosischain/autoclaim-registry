// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


interface ISBCDepositContract {
    // Events
    event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index);

    // External functions
    function get_deposit_root() external view returns (bytes32);
    function get_deposit_count() external view returns (bytes memory);
    function deposit(bytes memory pubkey, bytes memory withdrawal_credentials, bytes memory signature, bytes32 deposit_data_root, uint256 stake_amount) external;
    function batchDeposit(bytes calldata pubkeys, bytes calldata withdrawal_credentials, bytes calldata signatures, bytes32[] calldata deposit_data_roots) external;
    function onTokenTransfer(address from, uint256 stake_amount, bytes calldata data) external returns (bool);
    function claimTokens(address _token, address _to) external;
    function claimWithdrawal(address _address) external;
    function claimWithdrawals(address[] calldata _addresses) external;
    function executeSystemWithdrawals(uint256 /* _deprecatedUnused */, uint64[] calldata _amounts, address[] calldata _addresses) external;
    function executeSystemWithdrawals(uint64[] calldata _amounts, address[] calldata _addresses) external;
    function unwrapTokens(address _unwrapper, address _token) external;
    function withdrawableAmount(address _address) external view returns (uint256);
    // Supporting Interface function
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}
