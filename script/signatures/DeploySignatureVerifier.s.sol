// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "src/signatures/SignatureVerifier.sol";

contract DeploySignatureVerifier is Script {
    function run() public {
        // Load private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        SignatureVerifier verifier = new SignatureVerifier("Web3Snippets", "1");
        address contractAddress = address(verifier);
        
        vm.stopBroadcast();

        // Log deployment information
        console2.log("\n=== Deployment Summary ===");
        console2.log("SignatureVerifier deployed to:", contractAddress);
        console2.log("Block Number:", block.number);
        console2.log("Network:", block.chainid);
        
        // Add network-specific explorer URLs
        if (block.chainid == 11155111) {
            console2.log("Sepolia Etherscan:");
            console2.log("https://sepolia.etherscan.io/address/%s", contractAddress);
        } else if (block.chainid == 84532) {
            console2.log("Base Sepolia Explorer:");
            console2.log("https://sepolia.basescan.org/address/%s", contractAddress);
        }
    }
}