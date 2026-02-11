// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Reputation} from "../../src/interfaces/IERC8004Reputation.sol";
import {IERC8004Identity} from "../../src/interfaces/IERC8004Identity.sol";
import {IERC8004Validation} from "../../src/interfaces/IERC8004Validation.sol";

/**
 * @title FullRegistrationFlowTest
 * @notice Integration test for complete agent lifecycle
 */
contract FullRegistrationFlowTest is TestHelper {
    function test_FullFlow_RegistrationToDeregistration() public {
        // Step 1: Register agent with PLASMA stake
        uint256 balanceBeforeRegistration = address(alice).balance;
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        assertEq(identityRegistry.ownerOf(agentId), alice);
        assertEq(address(alice).balance, balanceBeforeRegistration - STAKE_AMOUNT);

        // Step 2: Submit feedback
        giveFeedback(bob, agentId, 90, "quality", "excellent");
        giveFeedback(charlie, agentId, 85, "speed", "fast");

        // Step 3: Request validation
        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");
        submitValidationResponse(validator1, requestHash, 95);

        // Step 4: Check reputation summary
        address[] memory clients = new address[](0);
        IERC8004Reputation.ReputationSummary memory summary =
            reputationRegistry.getSummary(agentId, clients, "", "");
        assertEq(summary.totalCount, 2);
        assertEq(summary.averageValue, 87); // (90 + 85) / 2

        // Step 5: Deregister and verify refund
        vm.prank(alice);
        identityRegistry.deregister(agentId);

        assertEq(address(alice).balance, balanceBeforeRegistration);
        assertFalse(identityRegistry.exists(agentId));
    }

    function test_FullFlow_WithSlashing() public {
        // Step 1: Register agent
        uint256 balanceBeforeRegistration = address(alice).balance;
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Step 2: Submit bad feedback (trigger slashing)
        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");
        giveFeedback(deployer, agentId, -60, "quality", "poor");

        // Step 3: Verify slashing occurred
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2);
        assertTrue(isSlashed);

        // Step 4: Deregister and verify partial refund
        vm.prank(alice);
        identityRegistry.deregister(agentId);

        // Should only get back 50% of stake
        assertEq(address(alice).balance, balanceBeforeRegistration - (STAKE_AMOUNT / 2));
    }

    function test_FullFlow_MultipleAgents() public {
        // Register multiple agents
        uint256 agentId1 = registerAgent(alice, "ipfs://agent1");
        uint256 agentId2 = registerAgent(alice, "ipfs://agent2");
        uint256 agentId3 = registerAgent(bob, "ipfs://agent3");

        assertEq(identityRegistry.totalSupply(), 3);
        assertEq(identityRegistry.balanceOf(alice), 2);
        assertEq(identityRegistry.balanceOf(bob), 1);

        // Give feedback to different agents
        giveFeedback(bob, agentId1, 90, "quality", "excellent");
        giveFeedback(charlie, agentId2, 80, "quality", "good");
        giveFeedback(alice, agentId3, 85, "quality", "great");

        // Verify separate reputation tracking
        address[] memory clients = new address[](0);
        IERC8004Reputation.ReputationSummary memory summary1 =
            reputationRegistry.getSummary(agentId1, clients, "", "");
        IERC8004Reputation.ReputationSummary memory summary2 =
            reputationRegistry.getSummary(agentId2, clients, "", "");

        assertEq(summary1.averageValue, 90);
        assertEq(summary2.averageValue, 80);
    }

    function test_FullFlow_WithMetadataUpdates() public {
        // Register with initial metadata
        vm.startPrank(alice);

        IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](1);
        metadata[0] = IERC8004Identity.MetadataEntry({key: "version", value: abi.encode("1.0.0")});

        uint256 agentId = identityRegistry.register{value: STAKE_AMOUNT}("ipfs://agent1", metadata);

        // Update metadata
        identityRegistry.setMetadata(agentId, "version", abi.encode("2.0.0"));
        identityRegistry.setMetadata(agentId, "name", abi.encode("Alice Agent"));

        // Update URI
        identityRegistry.setAgentURI(agentId, "ipfs://agent1-v2");

        vm.stopPrank();

        // Verify updates
        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "version"), (string)), "2.0.0");
        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "name"), (string)), "Alice Agent");
        assertEq(identityRegistry.getAgentURI(agentId), "ipfs://agent1-v2");
    }

    function test_FullFlow_FeedbackRevocation() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Submit feedback
        uint64 feedback1 = giveFeedback(bob, agentId, 90, "quality", "excellent");
        uint64 feedback2 = giveFeedback(charlie, agentId, 80, "quality", "good");
        giveFeedback(validator1, agentId, 85, "quality", "great");

        // Check initial summary
        address[] memory clients = new address[](0);
        IERC8004Reputation.ReputationSummary memory summaryBefore =
            reputationRegistry.getSummary(agentId, clients, "", "");
        assertEq(summaryBefore.totalCount, 3);
        assertEq(summaryBefore.averageValue, 85); // (90 + 80 + 85) / 3

        // Revoke one feedback
        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, feedback1);

        // Check updated summary
        IERC8004Reputation.ReputationSummary memory summaryAfter =
            reputationRegistry.getSummary(agentId, clients, "", "");
        assertEq(summaryAfter.totalCount, 2);
        assertEq(summaryAfter.averageValue, 82); // (80 + 85) / 2
    }

    function test_FullFlow_ValidationLifecycle() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Request multiple validations
        bytes32 request1 = requestValidation(bob, validator1, agentId, "security");
        bytes32 request2 = requestValidation(bob, validator2, agentId, "performance");
        bytes32 request3 = requestValidation(charlie, validator1, agentId, "security");

        // Check pending state
        address[] memory validators = new address[](0);
        IERC8004Validation.ValidationSummary memory summaryPending =
            validationRegistry.getSummary(agentId, validators, "");
        assertEq(summaryPending.pendingCount, 3);

        // Submit responses
        submitValidationResponse(validator1, request1, 90);
        submitValidationResponse(validator2, request2, 40);
        submitValidationResponse(validator1, request3, 75);

        // Check final summary
        IERC8004Validation.ValidationSummary memory summaryFinal =
            validationRegistry.getSummary(agentId, validators, "");
        assertEq(summaryFinal.pendingCount, 0);
        assertEq(summaryFinal.passedCount, 2); // >= 50
        assertEq(summaryFinal.failedCount, 1); // < 50
        assertEq(summaryFinal.averageScore, 68); // (90 + 40 + 75) / 3
    }
}
