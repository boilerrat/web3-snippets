// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/recovery/EmergencyRecovery.sol";

contract DeployEmergencyRecovery is Script {
    function run() public {
        // Load private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        EmergencyRecovery recovery = new EmergencyRecovery();
        address contractAddress = address(recovery);
        
        vm.stopBroadcast();

        // Log deployment information
        console2.log("\n=== Deployment Summary ===");
        console2.log("EmergencyRecovery deployed to:", contractAddress);
        console2.log("Block Number:", block.number);
        console2.log("Base Sepolia Explorer:");
        console2.log("https://sepolia.basescan.org/address/%s", contractAddress);
    }
}