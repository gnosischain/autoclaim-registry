// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockSBCDepositContract {
    mapping(address => uint256) private amounts;
    MockERC20 public token;

    constructor() {
        token = new MockERC20("Gosis Token", "GNO");
    }

    function fund(uint256 _numberOfAddresses, uint256 _amount) external { 
        token.mint(address(this), _numberOfAddresses *_amount);
        for (uint160 i = 1; i <= _numberOfAddresses; i++) {
            _setWithdrawableAmount(address(i), _amount);
        }
    }

    function _setWithdrawableAmount(address _address, uint256 _amount) private {
        amounts[_address] = _amount;
    }

    function claimWithdrawal(address _address) external {
        if (amounts[_address] > 0) {
            token.transfer(_address, amounts[_address]);
        }
        amounts[_address] = 0;
    }

    function withdrawableAmount(address _address) external view returns (uint256) {
        return amounts[_address];
    }
}

contract MockERC20 is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
