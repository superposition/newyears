// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StakingManager} from "../src/StakingManager.sol";
import {AgentIdentityRegistry} from "../src/AgentIdentityRegistry.sol";
import {ReputationRegistry} from "../src/ReputationRegistry.sol";
import {ValidationRegistry} from "../src/ValidationRegistry.sol";
import {MockPLASMAToken} from "../src/mocks/MockPLASMAToken.sol";

/**
 * @title Deploy
 * @notice Base deployment script for ERC-8004 contracts
 * @dev Orchestrates the deployment sequence with proper dependency wiring
 */
contract Deploy is Script {
    // Deployed contracts
    StakingManager public stakingManager;
    AgentIdentityRegistry public identityRegistry;
    ReputationRegistry public reputationRegistry;
    ValidationRegistry public validationRegistry;

    // PLASMA token address (set by child scripts or env var)
    address public plasmaTokenAddress;

    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deploying contracts with deployer:", deployer);
        console2.log("Chain ID:", block.chainid);

        // Get PLASMA token address from environment or deploy mock
        plasmaTokenAddress = vm.envOr("PLASMA_TOKEN_ADDRESS", address(0));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockPLASMAToken if not provided
        if (plasmaTokenAddress == address(0)) {
            console2.log("No PLASMA_TOKEN_ADDRESS provided, deploying MockPLASMAToken...");
            MockPLASMAToken plasmaToken = new MockPLASMAToken();
            plasmaTokenAddress = address(plasmaToken);
            console2.log("MockPLASMAToken deployed at:", plasmaTokenAddress);
        } else {
            console2.log("Using existing PLASMA token at:", plasmaTokenAddress);
        }

        // Deploy contracts in dependency order
        console2.log("\n=== Deploying Contracts ===");

        // 1. Deploy StakingManager
        console2.log("1. Deploying StakingManager...");
        stakingManager = new StakingManager(plasmaTokenAddress);
        console2.log("   StakingManager deployed at:", address(stakingManager));

        // 2. Deploy AgentIdentityRegistry
        console2.log("2. Deploying AgentIdentityRegistry...");
        identityRegistry = new AgentIdentityRegistry(address(stakingManager));
        console2.log("   AgentIdentityRegistry deployed at:", address(identityRegistry));

        // 3. Deploy ReputationRegistry
        console2.log("3. Deploying ReputationRegistry...");
        reputationRegistry = new ReputationRegistry(address(identityRegistry));
        console2.log("   ReputationRegistry deployed at:", address(reputationRegistry));

        // 4. Deploy ValidationRegistry
        console2.log("4. Deploying ValidationRegistry...");
        validationRegistry = new ValidationRegistry(address(identityRegistry));
        console2.log("   ValidationRegistry deployed at:", address(validationRegistry));

        // Wire up contracts
        console2.log("\n=== Wiring Contracts ===");

        console2.log("5. Setting IdentityRegistry in StakingManager...");
        stakingManager.setIdentityRegistry(address(identityRegistry));

        console2.log("6. Setting ReputationRegistry in StakingManager...");
        stakingManager.setReputationRegistry(address(reputationRegistry));

        vm.stopBroadcast();

        // Print deployment summary
        console2.log("\n=== Deployment Summary ===");
        console2.log("PLASMA Token:           ", plasmaTokenAddress);
        console2.log("StakingManager:         ", address(stakingManager));
        console2.log("AgentIdentityRegistry:  ", address(identityRegistry));
        console2.log("ReputationRegistry:     ", address(reputationRegistry));
        console2.log("ValidationRegistry:     ", address(validationRegistry));
        console2.log("\nDeployment completed successfully!");

        // Save deployment addresses to file
        saveDeploymentAddresses();
    }

    function saveDeploymentAddresses() internal {
        string memory json = "";
        json = vm.serializeAddress("addresses", "plasmaToken", plasmaTokenAddress);
        json = vm.serializeAddress("addresses", "stakingManager", address(stakingManager));
        json = vm.serializeAddress("addresses", "identityRegistry", address(identityRegistry));
        json = vm.serializeAddress("addresses", "reputationRegistry", address(reputationRegistry));
        json = vm.serializeAddress("addresses", "validationRegistry", address(validationRegistry));

        string memory filename = string.concat("deployments-", vm.toString(block.chainid), ".json");
        vm.writeJson(json, filename);
        console2.log("\nDeployment addresses saved to:", filename);
    }
}
