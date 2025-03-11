// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Curve {
    // some interfaces claim the i and j input to be int128, but they are uint256
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function price_oracle() external returns (uint256);
}

interface Balancer {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function getPoolTokenInfo(
        bytes32 poolId,
        IERC20 token
    )
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );
}

interface IAsset {
    // used in balancer, copied from their repo
    // solhint-disable-previous-line no-empty-blocks
}

interface IClaimAction {
    function executePostClaimAction(
        address _withdrawalAddress,
        uint256 _amount
    ) external;
}
