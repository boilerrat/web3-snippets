 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */



import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/tokens/SafeERC20Transfer.sol";

contract DeploySafeERC20Transfer is Script {
    function run() public {
        // Load private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        SafeERC20Transfer safeTransfer = new SafeERC20Transfer();
        address contractAddress = address(safeTransfer);
        
        vm.stopBroadcast();

        // Log deployment information
        console2.log("\n=== Deployment Summary ===");
        console2.log("SafeERC20Transfer deployed to:", contractAddress);
        console2.log("Block Number:", block.number);
        console2.log("Base Sepolia Explorer:");
        console2.log("https://sepolia.basescan.org/address/%s", contractAddress);
    }
}