// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */

import "forge-std/Test.sol";
import "../../src/recovery/EmergencyRecovery.sol";
import "../../test/mocks/MockERC20.sol";

contract EmergencyRecoveryTest is Test {
    EmergencyRecovery public recovery;
    MockERC20 public token;
    
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address[] public signers;
    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint256 public constant TOKEN_AMOUNT = 1000 * 10**18;
    
    event EthRecovered(address indexed requestor, address indexed to, uint256 amount);
    event TokensRecovered(address indexed token, address indexed requestor, address indexed to, uint256 amount);
    event RecoveryRequested(uint256 indexed requestId, address indexed requestor, address token, uint256 amount);
    event RecoveryApproved(uint256 indexed requestId, address indexed signer);
    event MultisigEnabled(uint256 requiredApprovals, address[] signers);
    
    function setUp() public {
        // Deploy contracts as owner
        vm.startPrank(owner);
        recovery = new EmergencyRecovery(); // Contract will set owner as msg.sender
        token = new MockERC20();
        vm.stopPrank();
        
        // Setup signers
        signers = new address[](3);
        signers[0] = makeAddr("signer1");
        signers[1] = makeAddr("signer2");
        signers[2] = makeAddr("signer3");
        
        // Fund contract
        vm.deal(address(recovery), INITIAL_BALANCE);
        deal(address(token), address(recovery), TOKEN_AMOUNT);
    }
    
    // Basic Recovery Tests
    function testRequestAndExecuteEthRecovery() public {
        uint256 amount = 1 ether;
        uint256 userBalanceBefore = user.balance;
        
        // Request recovery
        vm.prank(user);
        recovery.requestEthRecovery(user, amount);
        
        // Execute recovery
        vm.prank(owner);
        recovery.executeRecovery(1);
        
        assertEq(user.balance - userBalanceBefore, amount);
    }
    
    function testRequestAndExecuteTokenRecovery() public {
        uint256 amount = 100 * 10**18;
        uint256 userBalanceBefore = token.balanceOf(user);
        
        // Request recovery
        vm.prank(user);
        recovery.requestTokenRecovery(address(token), user, amount);
        
        // Execute recovery
        vm.prank(owner);
        recovery.executeRecovery(1);
        
        assertEq(token.balanceOf(user) - userBalanceBefore, amount);
    }
    
    // Multisig Tests
    function testEnableMultisig() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit MultisigEnabled(2, signers);
        recovery.enableMultisig(signers, 2);
        
        assertTrue(recovery.isMultisigEnabled());
        assertEq(recovery.requiredApprovals(), 2);
    }
    
    function testMultisigRecovery() public {
        // Enable multisig
        vm.prank(owner);
        recovery.enableMultisig(signers, 2);
        
        // Request recovery
        vm.prank(user);
        recovery.requestEthRecovery(user, 1 ether);
        
        // First approval
        vm.prank(signers[0]);
        recovery.approveRecovery(1);
        
        // Second approval should trigger execution
        uint256 userBalanceBefore = user.balance;
        vm.prank(signers[1]);
        recovery.approveRecovery(1);
        
        assertEq(user.balance - userBalanceBefore, 1 ether);
    }
    
    // Error Tests
    function testFailInvalidSignersCount() public {
        vm.prank(owner);
        recovery.enableMultisig(signers, 4); // More approvals than signers
    }
    
    function testFailUnauthorizedSigner() public {
        vm.prank(owner);
        recovery.enableMultisig(signers, 2);
        
        vm.prank(user);
        recovery.requestEthRecovery(user, 1 ether);
        
        vm.prank(user);
        recovery.approveRecovery(1);
    }
    
    function testFailDoubleApproval() public {
        vm.prank(owner);
        recovery.enableMultisig(signers, 2);
        
        vm.prank(user);
        recovery.requestEthRecovery(user, 1 ether);
        
        vm.prank(signers[0]);
        recovery.approveRecovery(1);
        
        vm.prank(signers[0]);
        recovery.approveRecovery(1);
    }
    
    function testFailInvalidRecoveryRequest() public {
        vm.prank(owner);
        recovery.executeRecovery(999); // Non-existent request
    }
    
    // Test Disable Multisig
    function testDisableMultisig() public {
        // Enable multisig first
        vm.startPrank(owner);
        recovery.enableMultisig(signers, 2);
        assertTrue(recovery.isMultisigEnabled());
        
        // Disable multisig
        recovery.disableMultisig();
        assertFalse(recovery.isMultisigEnabled());
        assertEq(recovery.requiredApprovals(), 0);
        
        // Check that no signers remain
        for (uint i = 0; i < signers.length; i++) {
            assertFalse(recovery.isApprovedSigner(signers[i]));
        }
        vm.stopPrank();
    }
    
    // Balance Check Tests
    function testGetBalances() public view {
        assertEq(recovery.getEthBalance(), INITIAL_BALANCE);
        assertEq(recovery.getTokenBalance(address(token)), TOKEN_AMOUNT);
    }
    
    // Fuzz Tests
    function testFuzzRecoveryAmount(uint256 amount) public {
        // Bound the amount between 1 wei and initial balance to avoid zero amount error
        amount = bound(amount, 1, INITIAL_BALANCE);
        
        vm.prank(user);
        recovery.requestEthRecovery(user, amount);
        
        uint256 userBalanceBefore = user.balance;
        vm.prank(owner);
        recovery.executeRecovery(1);
        
        assertEq(user.balance - userBalanceBefore, amount);
    }
}