// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICrossChainBridge {
    function swapCrossChain(address token, uint256 amount, address to, uint256 targetChainId) external;
}

contract OpenDexV2 {
    address public factory;
    address public crossChainBridge;

    event CrossChainSwap(address indexed user, address token, uint amount, uint targetChainId);

    constructor(address _factory, address _crossChainBridge) {
        factory = _factory;
        crossChainBridge = _crossChainBridge;
    }

    // Add liquidity for cross-chain functionality
    function addLiquidityCrossChain(address tokenA, address tokenB, uint amountA, uint amountB) external {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }

        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
    }

    // Cross-chain swap functionality
    function swapCrossChain(address token, uint amount, address to, uint targetChainId) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        ICrossChainBridge(crossChainBridge).swapCrossChain(token, amount, to, targetChainId);
        emit CrossChainSwap(msg.sender, token, amount, targetChainId);
    }
}
