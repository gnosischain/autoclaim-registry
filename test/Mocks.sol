// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MockSBCDepositContract {
    mapping(address => uint256) private amounts;
    MockERC20 public token;

    constructor() {
        token = new MockERC20();
    }

    function fund(uint256 _numberOfAddresses, uint256 _amount) external {
        token.setBalance(address(this), _amount);
        for (uint160 i = 0; i < _numberOfAddresses; i++) {
            _setWithdrawableAmount(address(i), _amount);
        }
    }

    function _setWithdrawableAmount(address _address, uint256 _amount) private {
        amounts[_address] = _amount;
    }

    function claimWithdrawal(address _address) external {
        amounts[_address] = 0;
        if (amounts[_address] > 0) {
            token.transfer(_address, amounts[_address]);
        }
    }

    function withdrawableAmount(address _address) external view returns (uint256) {
        return amounts[_address];
    }
}

contract MockERC20 {
    mapping(address => uint256) private balances;

    function setBalance(address _address, uint256 _amount) external {
        balances[_address] = _amount;
    }

    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _amount) external {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
}
