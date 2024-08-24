// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainStaking {
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => StakeInfo) public stakes;
    address public rewardToken;
    uint256 public rewardRate;

    event Staked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _rewardToken, uint256 _rewardRate) {
        rewardToken = _rewardToken;
        rewardRate = _rewardRate;
    }

    function stake(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = StakeInfo(amount, block.timestamp);
        emit Staked(msg.sender, amount);
    }

    function claimRewards() external {
        StakeInfo memory stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "No stake found");
        uint256 reward = (block.timestamp - stakeInfo.timestamp) * rewardRate;
        IERC20(rewardToken).transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }
}
