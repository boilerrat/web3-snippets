// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/merkle/MerkleProofValidator.sol";

contract DeployMerkleProofValidator is Script {
    function run() public {
        // Load private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Initial merkle root for testing (you can update this)
        bytes32 initialRoot = 0x1234567890123456789012345678901234567890123456789012345678901234;
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        MerkleProofValidator validator = new MerkleProofValidator(initialRoot);
        address contractAddress = address(validator);
        
        vm.stopBroadcast();

        // Log deployment information
        console2.log("\n=== Deployment Summary ===");
        console2.log("MerkleProofValidator deployed to:", contractAddress);
        console2.log("Initial Merkle Root:", vm.toString(initialRoot));
        console2.log("Block Number:", block.number);
        console2.log("Base Sepolia Explorer:");
        console2.log("https://sepolia.basescan.org/address/%s", contractAddress);
    }
}