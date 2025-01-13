// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SafeERC20Transfer {
    error TransferFailed();
    
    function safeTransfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );
        
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
        return true;
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
        
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
        return true;
    }
}
