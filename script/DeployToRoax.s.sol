// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Deploy} from "./Deploy.s.sol";

/**
 * @title DeployToRoax
 * @notice Deployment script for ROAX network (chainID 135)
 * @dev Run with: forge script script/DeployToRoax.s.sol --rpc-url https://devrpc.roax.net --broadcast --legacy
 */
contract DeployToRoax is Script {
    function run() external {
        console2.log("\n=================================");
        console2.log("Deploying to ROAX Network");
        console2.log("RPC URL: https://devrpc.roax.net");
        console2.log("Chain ID: 135");
        console2.log("=================================\n");

        // Verify we're on ROAX network
        require(block.chainid == 135, "Not on ROAX network (chainID 135)");

        // Check for PLASMA token address
        address plasmaTokenAddress = vm.envOr("PLASMA_TOKEN_ADDRESS", address(0));
        if (plasmaTokenAddress == address(0)) {
            console2.log("WARNING: No PLASMA_TOKEN_ADDRESS provided!");
            console2.log("A MockPLASMAToken will be deployed for testing purposes.");
            console2.log("For production, set PLASMA_TOKEN_ADDRESS in your .env file.");
        }

        // Execute deployment using the Deploy script logic
        Deploy deployScript = new Deploy();
        deployScript.run();

        console2.log("\n=================================");
        console2.log("ROAX Deployment Complete!");
        console2.log("=================================");
    }
}
