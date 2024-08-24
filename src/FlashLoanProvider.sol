// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashLoanProvider {
    event LoanTaken(address borrower, uint256 amount, address token);

    function flashLoan(address token, uint256 amount, bytes calldata data) external {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Not enough liquidity");

        IERC20(token).transfer(msg.sender, amount);

        (bool success,) = msg.sender.call(data);
        require(success, "Loan execution failed");

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Loan not repaid");

        emit LoanTaken(msg.sender, amount, token);
    }
}
