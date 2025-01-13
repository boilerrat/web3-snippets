// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/tokens/SafeERC20Transfer.sol";
import "../../test/mocks/MockERC20.sol";
import "../../test/mocks/NonStandardERC20.sol";

contract SafeERC20TransferTest is Test {
    SafeERC20Transfer public safeTransfer;
    MockERC20 public standardToken;
    NonStandardERC20 public nonStandardToken;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant INITIAL_BALANCE = 1000 * 10**18;
    
    function setUp() public {
        // Deploy contracts
        safeTransfer = new SafeERC20Transfer();
        standardToken = new MockERC20();
        nonStandardToken = new NonStandardERC20();
        
        // Setup initial balances
        deal(address(standardToken), address(safeTransfer), INITIAL_BALANCE);
        deal(address(nonStandardToken), address(safeTransfer), INITIAL_BALANCE);
        deal(address(standardToken), alice, INITIAL_BALANCE);
        deal(address(nonStandardToken), alice, INITIAL_BALANCE);
    }

    function testSafeTransferStandardToken() public {
        uint256 transferAmount = 100 * 10**18;
        
        uint256 bobBalanceBefore = standardToken.balanceOf(bob);
        safeTransfer.safeTransfer(IERC20(address(standardToken)), bob, transferAmount);
        uint256 bobBalanceAfter = standardToken.balanceOf(bob);
        
        assertEq(bobBalanceAfter - bobBalanceBefore, transferAmount, "Transfer amount mismatch");
    }

    function testSafeTransferNonStandardToken() public {
        uint256 transferAmount = 100 * 10**18;
        
        uint256 bobBalanceBefore = nonStandardToken.balanceOf(bob);
        safeTransfer.safeTransfer(IERC20(address(nonStandardToken)), bob, transferAmount);
        uint256 bobBalanceAfter = nonStandardToken.balanceOf(bob);
        
        assertEq(bobBalanceAfter - bobBalanceBefore, transferAmount, "Transfer amount mismatch");
    }

    function testSafeTransferFromStandardToken() public {
        uint256 transferAmount = 100 * 10**18;
        
        // Approve transfers
        vm.startPrank(alice);
        standardToken.approve(address(safeTransfer), transferAmount);
        
        uint256 bobBalanceBefore = standardToken.balanceOf(bob);
        safeTransfer.safeTransferFrom(
            IERC20(address(standardToken)),
            alice,
            bob,
            transferAmount
        );
        uint256 bobBalanceAfter = standardToken.balanceOf(bob);
        
        assertEq(bobBalanceAfter - bobBalanceBefore, transferAmount, "Transfer amount mismatch");
        vm.stopPrank();
    }

    function testRevertInsufficientBalance() public {
        uint256 transferAmount = INITIAL_BALANCE + 1;
        
        vm.expectRevert("Transfer failed");
        safeTransfer.safeTransfer(IERC20(address(standardToken)), bob, transferAmount);
    }

    function testRevertInsufficientAllowance() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.expectRevert("Transfer failed");
        safeTransfer.safeTransferFrom(
            IERC20(address(standardToken)),
            alice,
            bob,
            transferAmount
        );
    }

    function testFuzzingSafeTransfer(uint256 amount) public {
        // Bound the amount to something reasonable
        amount = bound(amount, 0, INITIAL_BALANCE);
        
        uint256 bobBalanceBefore = standardToken.balanceOf(bob);
        safeTransfer.safeTransfer(IERC20(address(standardToken)), bob, amount);
        uint256 bobBalanceAfter = standardToken.balanceOf(bob);
        
        assertEq(bobBalanceAfter - bobBalanceBefore, amount, "Transfer amount mismatch");
    }
}