// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Reputation} from "../../src/interfaces/IERC8004Reputation.sol";

contract ReputationRegistryTest is TestHelper {
    function test_GiveFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        IERC8004Reputation.Feedback memory feedback = reputationRegistry.getFeedback(agentId, feedbackIndex);
        assertEq(feedback.client, bob);
        assertEq(feedback.agent, agentId);
        assertEq(feedback.value, 80);
        assertEq(feedback.tag1, "speed");
        assertEq(feedback.tag2, "fast");
        assertFalse(feedback.isRevoked);
        assertEq(reputationRegistry.getFeedbackCount(agentId), 1);
    }

    function test_RevertWhen_GiveFeedback_AgentNotFound() public {
        vm.prank(bob);
        vm.expectRevert();
        reputationRegistry.giveFeedback(999, 80, 0, "speed", "fast", "");
    }

    function test_RevertWhen_GiveFeedback_SelfFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(alice);
        vm.expectRevert();
        reputationRegistry.giveFeedback(agentId, 80, 0, "speed", "fast", "");
    }

    function test_RevokeFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);

        IERC8004Reputation.Feedback memory feedback = reputationRegistry.getFeedback(agentId, feedbackIndex);
        assertTrue(feedback.isRevoked);
    }

    function test_RevertWhen_RevokeFeedback_NotOriginalSubmitter() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(charlie);
        vm.expectRevert();
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);
    }

    function test_RevertWhen_RevokeFeedback_AlreadyRevoked() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);

        vm.prank(bob);
        vm.expectRevert();
        reputationRegistry.revokeFeedback(agentId, feedbackIndex);
    }

    function test_RespondToFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(alice);
        reputationRegistry.respondToFeedback(agentId, feedbackIndex, "Thank you!");

        assertEq(reputationRegistry.getFeedbackResponse(agentId, feedbackIndex), "Thank you!");
    }

    function test_RevertWhen_RespondToFeedback_NotOwner() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        uint64 feedbackIndex = giveFeedback(bob, agentId, 80, "speed", "fast");

        vm.prank(charlie);
        vm.expectRevert();
        reputationRegistry.respondToFeedback(agentId, feedbackIndex, "Thank you!");
    }

    function test_GetSummary_All() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        address[] memory clients = new address[](0);
        IERC8004Reputation.ReputationSummary memory summary =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(summary.totalCount, 3);
        assertEq(summary.averageValue, 80); // (80 + 90 + 70) / 3
        assertEq(summary.minValue, 70);
        assertEq(summary.maxValue, 90);
    }

    function test_GetSummary_FilterByClient() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        address[] memory clients = new address[](1);
        clients[0] = bob;
        IERC8004Reputation.ReputationSummary memory summary =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(summary.totalCount, 1);
        assertEq(summary.averageValue, 80);
    }

    function test_GetSummary_FilterByTag() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "speed", "moderate");

        address[] memory clients = new address[](0);
        IERC8004Reputation.ReputationSummary memory summary =
            reputationRegistry.getSummary(agentId, clients, "speed", "");

        assertEq(summary.totalCount, 2);
        assertEq(summary.averageValue, 75); // (80 + 70) / 2
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
        IERC8004Reputation.ReputationSummary memory summary =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(summary.totalCount, 2); // Only 2 non-revoked
        assertEq(summary.averageValue, 75); // (80 + 70) / 2
    }

    function test_GetAllFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");

        IERC8004Reputation.Feedback[] memory allFeedback = reputationRegistry.getAllFeedback(agentId, true);
        assertEq(allFeedback.length, 2);
    }

    function test_GetAllFeedback_ExcludeRevoked() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        uint64 feedback2 = giveFeedback(charlie, agentId, 90, "quality", "excellent");

        vm.prank(charlie);
        reputationRegistry.revokeFeedback(agentId, feedback2);

        IERC8004Reputation.Feedback[] memory allFeedback = reputationRegistry.getAllFeedback(agentId, false);
        assertEq(allFeedback.length, 1);
        assertEq(allFeedback[0].client, bob);
    }

    function test_AutomaticSlashing_TriggeredOnBadReputation() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Give 5 bad feedbacks (average = -60)
        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");
        giveFeedback(deployer, agentId, -60, "quality", "poor");

        // Check if stake was slashed
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2); // 50% slashed
        assertTrue(isSlashed);
    }

    function test_NoSlashing_GoodReputation() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Give 5 good feedbacks
        giveFeedback(bob, agentId, 80, "quality", "good");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 85, "quality", "great");
        giveFeedback(validator2, agentId, 75, "quality", "good");
        giveFeedback(deployer, agentId, 70, "quality", "good");

        // Check stake is not slashed
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    function test_NoSlashing_InsufficientFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Give only 4 bad feedbacks (need 5 for slashing)
        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");

        // Check stake is not slashed
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }
}
