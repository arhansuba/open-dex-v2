// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiTokenPool {
    using SafeERC20 for IERC20;

    struct LiquidityProvider {
        mapping(address => uint256) tokenBalances; // Tracks each user's liquidity contribution per token
    }

    mapping(address => LiquidityProvider) private liquidityProviders; // Changed to private to avoid internal type error
    mapping(address => uint256) public totalPoolLiquidity; // Tracks the total pool liquidity for each token
    mapping(address => uint256) public tokenWeights; // Defines the weight for each supported token

    address public governance;
    address[] public supportedTokens;
    uint256 public liquidityFee = 10; // 0.1% fee on liquidity operations (in basis points)

    event LiquidityAdded(address indexed provider, address token, uint256 amount);
    event LiquidityRemoved(address indexed provider, address token, uint256 amount);
    event TokenWeightUpdated(address token, uint256 newWeight);

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not authorized");
        _;
    }

    constructor(address[] memory _tokens, uint256[] memory _weights, address _governance) {
        require(_tokens.length == _weights.length, "Token and weight mismatch");
        governance = _governance;
        supportedTokens = _tokens;

        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenWeights[_tokens[i]] = _weights[i];
        }
    }

    // Add liquidity for supported tokens
    function addLiquidity(address token, uint256 amount) external {
        require(isSupportedToken(token), "Token not supported");

        uint256 fee = (amount * liquidityFee) / 10000; // Calculate the fee (e.g., 0.1%)
        uint256 amountAfterFee = amount - fee;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amountAfterFee);
        IERC20(token).safeTransferFrom(msg.sender, governance, fee); // Fee sent to governance

        liquidityProviders[msg.sender].tokenBalances[token] += amountAfterFee;
        totalPoolLiquidity[token] += amountAfterFee;

        emit LiquidityAdded(msg.sender, token, amountAfterFee);
    }

    // Remove liquidity and refund the user
    function removeLiquidity(address token, uint256 amount) external {
        require(isSupportedToken(token), "Token not supported");
        require(liquidityProviders[msg.sender].tokenBalances[token] >= amount, "Insufficient balance");

        liquidityProviders[msg.sender].tokenBalances[token] -= amount;
        totalPoolLiquidity[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);
        emit LiquidityRemoved(msg.sender, token, amount);
    }

    // Check if a token is supported
    function isSupportedToken(address token) internal view returns (bool) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    // Getter function for liquidity provider token balances
    function getUserBalance(address user, address token) external view returns (uint256) {
        return liquidityProviders[user].tokenBalances[token];
    }

    // Governance function to update token weights in the pool
    function updateTokenWeight(address token, uint256 newWeight) external onlyGovernance {
        require(isSupportedToken(token), "Token not supported");
        tokenWeights[token] = newWeight;
        emit TokenWeightUpdated(token, newWeight);
    }

    // Governance function to add a new supported token
    function addSupportedToken(address token, uint256 weight) external onlyGovernance {
        require(!isSupportedToken(token), "Token already supported");
        supportedTokens.push(token);
        tokenWeights[token] = weight;
    }

    // Governance function to remove a supported token
    function removeSupportedToken(address token) external onlyGovernance {
        require(isSupportedToken(token), "Token not supported");
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == token) {
                supportedTokens[i] = supportedTokens[supportedTokens.length - 1]; // Move last token to the current position
                supportedTokens.pop(); // Remove the last element
                break;
            }
        }
        delete tokenWeights[token]; // Remove the weight for the token
    }

    // Governance function to adjust the liquidity fee
    function setLiquidityFee(uint256 _liquidityFee) external onlyGovernance {
        require(_liquidityFee <= 100, "Fee too high"); // Max 1% fee
        liquidityFee = _liquidityFee;
    }
}
