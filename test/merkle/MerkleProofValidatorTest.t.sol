// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/merkle/MerkleProofValidator.sol";

contract MerkleProofValidatorTest is Test {
    MerkleProofValidator public validator;
    
    // Test addresses
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    
    // Test amounts
    uint256 public constant ALICE_AMOUNT = 100 ether;
    uint256 public constant BOB_AMOUNT = 200 ether;
    uint256 public constant CAROL_AMOUNT = 300 ether;
    
    // Merkle tree data
    bytes32[] public proof;
    bytes32 public merkleRoot;
    
    function setUp() public {
        // Generate leaf nodes
        bytes32 aliceLeaf = keccak256(abi.encodePacked(alice, ALICE_AMOUNT));
        bytes32 bobLeaf = keccak256(abi.encodePacked(bob, BOB_AMOUNT));
        bytes32 carolLeaf = keccak256(abi.encodePacked(carol, CAROL_AMOUNT));
        
        // Create the first level of the tree (combining alice and bob)
        bytes32 aliceBobNode = hash(aliceLeaf, bobLeaf);
        
        // Create the root (combining aliceBob with carol)
        merkleRoot = hash(aliceBobNode, carolLeaf);
        
        // Deploy validator with our generated root
        validator = new MerkleProofValidator(merkleRoot);
        
        // Generate proof for alice
        // For alice's proof, we need:
        // 1. Bob's leaf (to combine with alice's leaf)
        // 2. Carol's leaf (to combine with aliceBob node)
        proof = new bytes32[](2);
        proof[0] = bobLeaf;
        proof[1] = carolLeaf;
    }

    function hash(bytes32 left, bytes32 right) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(left <= right ? left : right, left <= right ? right : left));
    }
    
    function testValidClaim() public {
        validator.claim(alice, ALICE_AMOUNT, proof);
        assertTrue(validator.hasClaimed(alice));
    }
    
    function testDoubleClaim() public {
        validator.claim(alice, ALICE_AMOUNT, proof);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("AlreadyClaimed()"))));
        validator.claim(alice, ALICE_AMOUNT, proof);
    }
    
    function testInvalidAmount() public {
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("InvalidProof()"))));
        validator.claim(alice, 999 ether, proof);
    }
    
    function testInvalidProof() public {
        // Modify the first proof element to make it invalid
        bytes32[] memory invalidProof = proof;
        invalidProof[0] = bytes32(uint256(proof[0]) + 1);
        
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("InvalidProof()"))));
        validator.claim(alice, ALICE_AMOUNT, invalidProof);
    }
    
    function testGetLeafHash() public view {
        bytes32 expectedHash = keccak256(abi.encodePacked(alice, ALICE_AMOUNT));
        bytes32 computedHash = validator.getLeafHash(alice, ALICE_AMOUNT);
        assertEq(computedHash, expectedHash);
    }
}