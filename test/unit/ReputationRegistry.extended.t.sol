// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Reputation} from "../../src/interfaces/IERC8004Reputation.sol";

contract ReputationRegistryExtendedTest is TestHelper {

    // ============ BOUNDARY CONDITIONS ============

    function test_NoSlashing_AtExactThreshold() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -50, "quality", "poor");
        giveFeedback(charlie, agentId, -50, "quality", "poor");
        giveFeedback(validator1, agentId, -50, "quality", "poor");
        giveFeedback(validator2, agentId, -50, "quality", "poor");
        giveFeedback(deployer, agentId, -50, "quality", "poor");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    function test_Slashing_JustBelowThreshold() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -51, "quality", "poor");
        giveFeedback(charlie, agentId, -51, "quality", "poor");
        giveFeedback(validator1, agentId, -51, "quality", "poor");
        giveFeedback(validator2, agentId, -51, "quality", "poor");
        giveFeedback(deployer, agentId, -51, "quality", "poor");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2);
        assertTrue(isSlashed);
    }

    // ============ MIXED FEEDBACK SCENARIOS ============

    function test_Slashing_MixedFeedbackCrossingThreshold() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 100, "quality", "excellent");
        giveFeedback(charlie, agentId, -100, "quality", "terrible");
        giveFeedback(validator1, agentId, -100, "quality", "terrible");
        giveFeedback(validator2, agentId, -51, "quality", "poor");
        giveFeedback(deployer, agentId, -104, "quality", "terrible");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2);
        assertTrue(isSlashed);
    }

    function test_NoSlashing_MajorityPositiveFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 50, "quality", "good");
        giveFeedback(charlie, agentId, 50, "quality", "good");
        giveFeedback(validator1, agentId, 50, "quality", "good");
        giveFeedback(validator2, agentId, -70, "quality", "poor");
        giveFeedback(deployer, agentId, -30, "quality", "poor");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    // ============ DECIMAL HANDLING ============

    function test_GiveFeedback_WithDecimals() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        reputationRegistry.giveFeedback(agentId, 9550, 2, "quality", "excellent", "", "", bytes32(0));

        (int128 value, uint8 decimals, , , ) = reputationRegistry.readFeedback(agentId, bob, 1);
        assertEq(value, 9550);
        assertEq(decimals, 2);

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, uint8 summaryDecimals) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 1);
        assertEq(summaryValue, 9550);
        assertEq(summaryDecimals, 2);
    }

    function test_GetSummary_ConsistentDecimals() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        reputationRegistry.giveFeedback(agentId, 9550, 2, "quality", "excellent", "", "", bytes32(0));

        vm.prank(charlie);
        reputationRegistry.giveFeedback(agentId, 8000, 2, "quality", "good", "", "", bytes32(0));

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, uint8 summaryDecimals) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 2);
        assertEq(summaryValue, 8775); // (9550 + 8000) / 2
        assertEq(summaryDecimals, 2);
    }

    // ============ REVOCATION EDGE CASES ============

    function test_Revocation_DoesNotUnslash() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");
        giveFeedback(deployer, agentId, -60, "quality", "poor");

        (uint256 stakedBefore, bool slashedBefore) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedBefore, STAKE_AMOUNT / 2);
        assertTrue(slashedBefore);

        // Revoke all bad feedback
        vm.prank(bob);
        reputationRegistry.revokeFeedback(agentId, 1);
        vm.prank(charlie);
        reputationRegistry.revokeFeedback(agentId, 1);
        vm.prank(validator1);
        reputationRegistry.revokeFeedback(agentId, 1);
        vm.prank(validator2);
        reputationRegistry.revokeFeedback(agentId, 1);
        vm.prank(deployer);
        reputationRegistry.revokeFeedback(agentId, 1);

        (uint256 stakedAfter, bool slashedAfter) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAfter, stakedBefore);
        assertTrue(slashedAfter);
    }

    function test_GoodFeedback_PreventsSlashing() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, -60, "quality", "poor");
        giveFeedback(charlie, agentId, -60, "quality", "poor");
        giveFeedback(validator1, agentId, -60, "quality", "poor");
        giveFeedback(validator2, agentId, -60, "quality", "poor");

        // 5th feedback is positive
        giveFeedback(deployer, agentId, 100, "quality", "excellent");

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    // ============ EMPTY STATE TESTS ============

    function test_GetSummary_NoFeedback() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, ) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 0);
        assertEq(summaryValue, 0);
    }

    function test_ReadAllFeedback_Empty() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        address[] memory emptyClients = new address[](0);
        (uint256[] memory agentIds, , , , , , ) =
            reputationRegistry.readAllFeedback(agentId, emptyClients, "", "", true);

        assertEq(agentIds.length, 0);
    }

    // ============ ADVANCED FILTERING ============

    function test_GetSummary_FilterByBothTags() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "speed", "fast");
        giveFeedback(charlie, agentId, 90, "speed", "excellent");
        giveFeedback(validator1, agentId, 70, "quality", "fast");

        address[] memory clients = new address[](0);
        (uint64 count, int128 summaryValue, ) =
            reputationRegistry.getSummary(agentId, clients, "speed", "fast");

        assertEq(count, 1);
        assertEq(summaryValue, 80);
    }

    function test_GetSummary_FilterByMultipleClients() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "quality", "good");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");
        giveFeedback(validator1, agentId, 70, "quality", "moderate");

        address[] memory clients = new address[](2);
        clients[0] = bob;
        clients[1] = charlie;

        (uint64 count, int128 summaryValue, ) =
            reputationRegistry.getSummary(agentId, clients, "", "");

        assertEq(count, 2);
        assertEq(summaryValue, 85); // (80 + 90) / 2
    }

    function test_GetSummary_EmptyClientFilterMatchesAll() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        giveFeedback(bob, agentId, 80, "quality", "good");
        giveFeedback(charlie, agentId, 90, "quality", "excellent");

        address[] memory emptyClients = new address[](0);
        (uint64 count, , ) =
            reputationRegistry.getSummary(agentId, emptyClients, "", "");

        assertEq(count, 2);
    }
}
