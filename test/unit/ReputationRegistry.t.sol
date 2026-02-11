// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Reputation} from "../../src/interfaces/IERC8004Reputation.sol";
import {ReputationRegistry} from "../../src/ReputationRegistry.sol";

contract ReputationRegistryTest is TestHelper {
    function test_GiveFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        // feedbackIndex should be 1-based
        assertEq(feedbackIndex, 1);

        (int128 value, uint8 decimals, string memory tag1, string memory tag2, bool isRevoked) =
            reputationRegistry.readFeedback(agentId, bob, feedbackIndex);
        assertEq(value, 80);
        assertEq(decimals, 0);
        assertEq(tag1, "speed");
        assertEq(tag2, "fast");
        assertFalse(isRevoked);
    }

    function test_GiveFeedback_MultipleFeedbackPerClient() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint64 fb1 = giveFeedback(bob, agentId, 80, "speed", "fast");
        uint64 fb2 = giveFeedback(bob, agentId, 90, "quality", "excellent");

        assertEq(fb1, 1);
        assertEq(fb2, 2);
        assertEq(reputationRegistry.getLastIndex(agentId, bob), 2);
    }

    function test_GiveFeedback_MultipleClients() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint64 fb1 = giveFeedback(bob, agentId, 80, "speed", "fast");
        uint64 fb2 = giveFeedback(charlie, agentId, 90, "quality", "excellent");

        // Each client has separate 1-based index
        assertEq(fb1, 1);
        assertEq(fb2, 1);
        assertEq(reputationRegistry.getLastIndex(agentId, bob), 1);
        assertEq(reputationRegistry.getLastIndex(agentId, charlie), 1);
    }

    function test_RevertWhen_GiveFeedback_AgentNotFound() public {
        vm.prank(bob);
        vm.expectRevert();
        reputationRegistry.giveFeedback(999, 80, 0, "speed", "fast", "", "", bytes32(0));
    }

    function test_RevertWhen_GiveFeedback_SelfFeedback_Owner() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(alice);
        vm.expectRevert(ReputationRegistry.SelfFeedbackNotAllowed.selector);
        reputationRegistry.giveFeedback(agentId, 80, 0, "speed", "fast", "", "", bytes32(0));
    }

    function test_RevertWhen_GiveFeedback_SelfFeedback_Operator() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Alice approves bob as operator
        vm.prank(alice);
        identityRegistry.setApprovalForAll(bob, true);

        // Bob (operator) also can't give self-feedback
        vm.prank(bob);
        vm.expectRevert(ReputationRegistry.SelfFeedbackNotAllowed.selector);
        reputationRegistry.giveFeedback(agentId, 80, 0, "speed", "fast", "", "", bytes32(0));
    }

    function test_RevertWhen_GiveFeedback_ValueTooLarge() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        vm.expectRevert(ReputationRegistry.ValueOutOfRange.selector);
        reputationRegistry.giveFeedback(agentId, type(int128).max, 0, "", "", "", "", bytes32(0));
    }

    function test_RevertWhen_GiveFeedback_DecimalsTooHigh() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        vm.expectRevert(ReputationRegistry.DecimalsTooHigh.selector);
        reputationRegistry.giveFeedback(agentId, 80, 19, "", "", "", "", bytes32(0));
    }

    function test_RevokeFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);

        (, , , , bool isRevoked) = reputationRegistry.readFeedback(agentId, bob, feedbackIndex);
        assertTrue(isRevoked);
    }

    function test_RevertWhen_RevokeFeedback_NotOriginalSubmitter() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        giveFeedback(bob, agentId, 80, "speed", "fast");

        // Charlie tries to revoke bob's feedback — will revert because feedbackIndex 1 doesn't exist for charlie
        vm.prank(charlie);
        vm.expectRevert(ReputationRegistry.FeedbackNotFound.selector);
        reputationRegistry.revokeFeedback(agentId, 1);
    }

    function test_RevertWhen_RevokeFeedback_AlreadyRevoked() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);

        vm.prank(bob);
        vm.expectRevert(ReputationRegistry.AlreadyRevoked.selector);
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);
    }

    function test_AppendResponse() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        // Anyone can respond
        appendFeedbackResponse(charlie, agentId, bob, feedbackIndex);

        address[] memory responders = new address[](0);
        uint64 count = reputationRegistry.getResponseCount(agentId, bob, feedbackIndex, responders);
        assertEq(count, 1);
    }

    function test_AppendResponse_MultipleResponders() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        appendFeedbackResponse(charlie, agentId, bob, feedbackIndex);
        appendFeedbackResponse(alice, agentId, bob, feedbackIndex);
        // Duplicate response from charlie (should not increment count)
        appendFeedbackResponse(charlie, agentId, bob, feedbackIndex);

        address[] memory responders = new address[](0);
        uint64 count = reputationRegistry.getResponseCount(agentId, bob, feedbackIndex, responders);
        assertEq(count, 2); // Only 2 unique responders
    }

    function test_GetClients() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");

        address[] memory clients = reputationRegistry.getClients(agentId);
        assertEq(clients.length, 2);
        assertEq(clients[0], bob);
        assertEq(clients[1], charlie);
    }

    function test_GetLastIndex() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(bob, agentId, 90, "quality", "excellent");

        assertEq(reputationRegistry.getLastIndex(agentId, bob), 2);
        assertEq(reputationRegistry.getLastIndex(agentId, charlie), 0);
    }

    function test_GetResponseCount() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        appendFeedbackResponse(charlie, agentId, bob, feedbackIndex);

        // Filter by specific responders
        address[] memory responders = new address[](2);
        responders[0] = charlie;
        responders[1] = validator1;

        uint64 count = reputationRegistry.getResponseCount(agentId, bob, feedbackIndex, responders);
        assertEq(count, 1); // Only charlie responded
    }

    function test_ReadFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        (int128 value, uint8 decimals, string memory tag1, string memory tag2, bool isRevoked) =
            reputationRegistry.readFeedback(agentId, bob, feedbackIndex);

        assertEq(value, 80);
        assertEq(decimals, 0);
        assertEq(tag1, "speed");
        assertEq(tag2, "fast");
        assertFalse(isRevoked);
    }

    function test_ReadAllFeedback_WithFilters() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        // Filter by tag1 = "speed"
        address[] memory emptyClients = new address[](0);
        (
            uint256[] memory agentIds,
            address[] memory clients,
            uint64[] memory feedbackIndexes,
            int128[] memory values,
            ,
            string[] memory tag1s,
        ) = reputationRegistry.readAllFeedback(agentId, emptyClients, "speed", "", true);

        assertEq(agentIds.length, 2);
        assertEq(clients[0], bob);
        assertEq(clients[1], validator1);
        assertEq(values[0], 80);
        assertEq(values[1], 70);
    }

    function test_GetSummary_All() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, uint8 summaryDecimals) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 3);
        assertEq(summaryValue, 80); // (80 + 90 + 70) / 3 = 80
        assertEq(summaryDecimals, 0);
    }

    function test_GetSummary_FilterByClient() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        address[] memory clients = new address[](1);
        clients[0] = bob;
        (uint64 count, int128 summaryValue,) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 1);
        assertEq(summaryValue, 80);
    }

    function test_GetSummary_FilterByTag() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue,) =
            reputationRegistry.getSummary(agentId, clients, "speed", "");

        assertEq(count, 2);
        assertEq(summaryValue, 75); // (80 + 70) / 2
    }

    function test_GetSummary_ExcludesRevoked() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        uint64 feedback2 = giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        // Revoke charlie's feedback
        vm.prank(charlie);
        reputationRegistry.revokeFeedback(agentId, feedback2);

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue,) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 2); // Only 2 non-revoked
        assertEq(summaryValue, 75); // (80 + 70) / 2
    }

    function test_GetSummary_WADNormalization() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Two feedbacks with different decimal places
        vm.prank(bob);
        reputationRegistry.giveFeedback(agentId, 9550, 2, "quality", "excellent", "", "", bytes32(0));

        vm.prank(charlie);
        reputationRegistry.giveFeedback(agentId, 8000, 2, "quality", "good", "", "", bytes32(0));

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, uint8 summaryDecimals) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 2);
        assertEq(summaryDecimals, 2);
        assertEq(summaryValue, 8775); // (9550 + 8000) / 2 = 8775
    }

    function test_AutomaticSlashing_TriggeredOnBadReputation() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");
        giveFeedback(deployer, agentId, -60, "quality", "poor");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2);
        assertTrue(isSlashed);
    }

    function test_NoSlashing_GoodReputation() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "quality", "good");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 85, "quality", "great");
        giveFeedback(validator2, agentId, 75, "quality", "good");
        giveFeedback(deployer, agentId, 70, "quality", "good");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    function test_NoSlashing_InsufficientFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }
}
