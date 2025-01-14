// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/signatures/SignatureVerifier.sol";

contract SignatureVerifierTest is Test {
    SignatureVerifier public verifier;
    
    // Test accounts
    address public alice;
    address public bob;
    uint256 public alicePrivateKey;
    
    // Test data
    string constant TEST_NAME = "TestApp";
    string constant TEST_VERSION = "1";
    string constant TEST_MESSAGE = "Hello Web3";
    uint256 constant FUTURE_DEADLINE = 2000000000; // Year 2033
    uint256 constant PAST_DEADLINE = 1600000000; // Year 2020
    
    function setUp() public {
        // Create deterministic private key and address for alice
        alicePrivateKey = 0xa11ce11111111111111111111111111111111111111111111111111111111111;
        alice = vm.addr(alicePrivateKey);
        bob = makeAddr("bob");
        
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        
        // Deploy verifier
        verifier = new SignatureVerifier(TEST_NAME, TEST_VERSION);
    }

    function testVerifyTypedSignature() public {
        uint256 nonce = 1;
        
        // Create EIP-712 signature
        bytes32 domainSeparator = _hashDomain(
            TEST_NAME,
            TEST_VERSION,
            block.chainid,
            address(verifier)
        );
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Message(string message,uint256 nonce,uint256 deadline)"),
                keccak256(bytes(TEST_MESSAGE)),
                nonce,
                FUTURE_DEADLINE
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Verify signature
        address signer = verifier.verifyTypedSignature(
            TEST_MESSAGE,
            nonce,
            FUTURE_DEADLINE,
            signature
        );
        
        assertEq(signer, alice, "Signer address mismatch");
    }

    function testVerifyPersonalSignature() public view {
        // Create personal message signature
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", bytes(TEST_MESSAGE).length, TEST_MESSAGE)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Verify signature
        address signer = verifier.verifyPersonalSignature(
            TEST_MESSAGE,
            signature
        );
        
        assertEq(signer, alice, "Signer address mismatch");
    }

    function testRevertExpiredSignature() public {
        uint256 nonce = 1;
        
        // Set block timestamp to after the deadline
        vm.warp(PAST_DEADLINE + 1);
        
        // Create signature with past deadline
        bytes32 domainSeparator = _hashDomain(
            TEST_NAME,
            TEST_VERSION,
            block.chainid,
            address(verifier)
        );
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Message(string message,uint256 nonce,uint256 deadline)"),
                keccak256(bytes(TEST_MESSAGE)),
                nonce,
                PAST_DEADLINE
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Verify it reverts
        vm.expectRevert(SignatureVerifier.InvalidSignature.selector);
        verifier.verifyTypedSignature(
            TEST_MESSAGE,
            nonce,
            PAST_DEADLINE,
            signature
        );
    }

    function testRevertSignatureReuse() public {
        uint256 nonce = 1;
        
        // Create valid signature
        bytes32 domainSeparator = _hashDomain(
            TEST_NAME,
            TEST_VERSION,
            block.chainid,
            address(verifier)
        );
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Message(string message,uint256 nonce,uint256 deadline)"),
                keccak256(bytes(TEST_MESSAGE)),
                nonce,
                FUTURE_DEADLINE
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // First verification should succeed
        verifier.verifyTypedSignature(
            TEST_MESSAGE,
            nonce,
            FUTURE_DEADLINE,
            signature
        );
        
        // Second verification should fail
        vm.expectRevert(SignatureVerifier.SignatureAlreadyUsed.selector);
        verifier.verifyTypedSignature(
            TEST_MESSAGE,
            nonce,
            FUTURE_DEADLINE,
            signature
        );
    }

    function testFuzzingTypedSignature(
        string memory message,
        uint256 nonce,
        uint256 deadline
    ) public {
        vm.assume(deadline > block.timestamp); // Ensure future deadline
        vm.assume(bytes(message).length > 0); // Ensure non-empty message
        
        // Create signature
        bytes32 domainSeparator = _hashDomain(
            TEST_NAME,
            TEST_VERSION,
            block.chainid,
            address(verifier)
        );
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Message(string message,uint256 nonce,uint256 deadline)"),
                keccak256(bytes(message)),
                nonce,
                deadline
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Verify signature
        address signer = verifier.verifyTypedSignature(
            message,
            nonce,
            deadline,
            signature
        );
        
        assertEq(signer, alice, "Signer address mismatch");
    }

    // Helper for creating domain separator hash
    function _hashDomain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
    }
}