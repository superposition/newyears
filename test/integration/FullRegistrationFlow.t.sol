// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Reputation} from "../../src/interfaces/IERC8004Reputation.sol";
import {IERC8004Identity} from "../../src/interfaces/IERC8004Identity.sol";
import {IERC8004Validation} from "../../src/interfaces/IERC8004Validation.sol";

contract FullRegistrationFlowTest is TestHelper {
    function test_FullFlow_RegistrationToDeregistration() public {
        uint256 balanceBeforeRegistration = address(alice).balance;
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        assertEq(identityRegistry.ownerOf(agentId), alice);
        assertEq(address(alice).balance, balanceBeforeRegistration - STAKE_AMOUNT);

        // Agent wallet auto-set
        assertEq(identityRegistry.getAgentWallet(agentId), alice);

        // Submit feedback
        giveFeedback(bob, agentId, 90, "quality", "excellent");
        giveFeedback(charlie, agentId, 85, "speed", "fast");

        // Request validation
        bytes32 requestHash = keccak256("security-audit");
        requestValidation(alice, validator1, agentId, requestHash);
        submitValidationResponse(validator1, requestHash, 95, "security");

        // Check reputation summary
        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, ) =
            reputationRegistry.getSummary(agentId, clients, "", "");
        assertEq(count, 2);
        assertEq(summaryValue, 87); // (90 + 85) / 2

        // Deregister and verify refund
        vm.prank(alice);
        identityRegistry.deregister(agentId);

        assertEq(address(alice).balance, balanceBeforeRegistration);
        assertFalse(identityRegistry.exists(agentId));
    }

    function test_FullFlow_WithSlashing() public {
        uint256 balanceBeforeRegistration = address(alice).balance;
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");
        giveFeedback(deployer, agentId, -60, "quality", "poor");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2);
        assertTrue(isSlashed);

        vm.prank(alice);
        identityRegistry.deregister(agentId);

        assertEq(address(alice).balance, balanceBeforeRegistration - (STAKE_AMOUNT / 2));
    }

    function test_FullFlow_MultipleAgents() public {
        uint256 agentId1 = registerAgent(alice, "ipfs://agent1");
        uint256 agentId2 = registerAgent(alice, "ipfs://agent2");
        uint256 agentId3 = registerAgent(bob, "ipfs://agent3");

        assertEq(identityRegistry.totalSupply(), 3);
        assertEq(identityRegistry.balanceOf(alice), 2);
        assertEq(identityRegistry.balanceOf(bob), 1);

        giveFeedback(bob, agentId1, 90, "quality", "excellent");
        giveFeedback(charlie, agentId2, 80, "quality", "good");
        giveFeedback(alice, agentId3, 85, "quality", "great");

        address[] memory clients = new address[](0);
        (uint64 count1, int128 val1, ) = reputationRegistry.getSummary(agentId1, clients, "", "");
        (uint64 count2, int128 val2, ) = reputationRegistry.getSummary(agentId2, clients, "", "");

        assertEq(val1, 90);
        assertEq(val2, 80);
    }

    function test_FullFlow_WithMetadataUpdates() public {
        vm.startPrank(alice);

        IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](1);
        metadata[0] = IERC8004Identity.MetadataEntry({metadataKey: "version", metadataValue: abi.encode("1.0.0")});

        uint256 agentId = identityRegistry.register{value: STAKE_AMOUNT}("ipfs://agent1", metadata);

        identityRegistry.setMetadata(agentId, "version", abi.encode("2.0.0"));
        identityRegistry.setMetadata(agentId, "name", abi.encode("Alice Agent"));
        identityRegistry.setAgentURI(agentId, "ipfs://agent1-v2");

        vm.stopPrank();

        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "version"), (string)), "2.0.0");
        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "name"), (string)), "Alice Agent");
        assertEq(identityRegistry.getAgentURI(agentId), "ipfs://agent1-v2");
    }

    function test_FullFlow_FeedbackRevocation() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint64 feedback1 = giveFeedback(bob, agentId, 90, "quality", "excellent");
        uint64 feedback2 = giveFeedback(charlie, agentId, 80, "quality", "good");
        giveFeedback(validator1, agentId, 85, "quality", "great");

        address[] memory clients = new address[](0);
        (uint64 countBefore, int128 avgBefore, ) =
            reputationRegistry.getSummary(agentId, clients, "", "");
        assertEq(countBefore, 3);
        assertEq(avgBefore, 85); // (90 + 80 + 85) / 3

        // Revoke bob's feedback (feedbackIndex 1 for bob)
        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, feedback1);

        (uint64 countAfter, int128 avgAfter, ) =
            reputationRegistry.getSummary(agentId, clients, "", "");
        assertEq(countAfter, 2);
        assertEq(avgAfter, 82); // (80 + 85) / 2
    }

    function test_FullFlow_ValidationLifecycle() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 req1 = keccak256("security-audit");
        bytes32 req2 = keccak256("perf-audit");
        bytes32 req3 = keccak256("security-audit-2");

        requestValidation(alice, validator1, agentId, req1);
        requestValidation(alice, validator2, agentId, req2);
        requestValidation(alice, validator1, agentId, req3);

        // All pending initially — getSummary only counts responded validations
        address[] memory validators = new address[](0);
        (uint64 countPending, ) = validationRegistry.getSummary(agentId, validators, "");
        assertEq(countPending, 0); // No responses yet

        submitValidationResponse(validator1, req1, 90, "security");
        submitValidationResponse(validator2, req2, 40, "performance");
        submitValidationResponse(validator1, req3, 75, "security");

        (uint64 countFinal, uint8 avgFinal) = validationRegistry.getSummary(agentId, validators, "");
        assertEq(countFinal, 3);
        assertEq(avgFinal, 68); // (90 + 40 + 75) / 3
    }

    function test_FullFlow_AppendResponse() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        // Agent owner responds
        appendFeedbackResponse(alice, agentId, bob, feedbackIndex);

        // Another user responds
        appendFeedbackResponse(charlie, agentId, bob, feedbackIndex);

        address[] memory responders = new address[](0);
        uint64 count = reputationRegistry.getResponseCount(agentId, bob, feedbackIndex, responders);
        assertEq(count, 2);
    }

    function test_FullFlow_MultipleRegisterOverloads() public {
        // Bare registration
        vm.prank(alice);
        uint256 agentId1 = identityRegistry.register{value: STAKE_AMOUNT}();

        // URI-only registration
        vm.prank(bob);
        uint256 agentId2 = identityRegistry.register{value: STAKE_AMOUNT}("ipfs://agent2");

        // Full registration
        IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](1);
        metadata[0] = IERC8004Identity.MetadataEntry({metadataKey: "name", metadataValue: abi.encode("Charlie Agent")});
        vm.prank(charlie);
        uint256 agentId3 = identityRegistry.register{value: STAKE_AMOUNT}("ipfs://agent3", metadata);

        assertEq(identityRegistry.totalSupply(), 3);
        assertEq(identityRegistry.getAgentWallet(agentId1), alice);
        assertEq(identityRegistry.getAgentWallet(agentId2), bob);
        assertEq(identityRegistry.getAgentWallet(agentId3), charlie);
        assertEq(identityRegistry.getAgentURI(agentId2), "ipfs://agent2");
        assertEq(abi.decode(identityRegistry.getMetadata(agentId3, "name"), (string)), "Charlie Agent");
    }
}
