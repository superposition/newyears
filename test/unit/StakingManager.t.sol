// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {StakingManager} from "../../src/StakingManager.sol";

contract StakingManagerTest is TestHelper {
    function test_Constructor() public view {
        assertEq(stakingManager.owner(), deployer);
        assertEq(stakingManager.STAKE_AMOUNT(), 0.1 ether);
        assertEq(stakingManager.SLASH_PERCENTAGE(), 50);
    }

    function test_SetIdentityRegistry() public {
        vm.prank(deployer);
        stakingManager.setIdentityRegistry(address(0x999));
        assertEq(stakingManager.identityRegistry(), address(0x999));
    }

    function test_RevertWhen_SetIdentityRegistry_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        stakingManager.setIdentityRegistry(address(0x999));
    }

    function test_RevertWhen_SetIdentityRegistry_ZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(StakingManager.InvalidAddress.selector);
        stakingManager.setIdentityRegistry(address(0));
    }

    function test_SetReputationRegistry() public {
        vm.prank(deployer);
        stakingManager.setReputationRegistry(address(0x999));
        assertEq(stakingManager.reputationRegistry(), address(0x999));
    }

    function test_Stake() public {
        uint256 agentId = 1;

        vm.deal(address(identityRegistry), 1 ether);
        vm.prank(address(identityRegistry));
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
        assertEq(stakingManager.getTotalStaked(), STAKE_AMOUNT);
    }

    function test_RevertWhen_Stake_NotIdentityRegistry() public {
        vm.prank(alice);
        vm.expectRevert(StakingManager.Unauthorized.selector);
        stakingManager.stake{value: STAKE_AMOUNT}(1);
    }

    function test_RevertWhen_Stake_AlreadyStaked() public {
        uint256 agentId = 1;

        vm.startPrank(address(identityRegistry));
        vm.deal(address(identityRegistry), 1 ether);
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        vm.expectRevert(StakingManager.AlreadyStaked.selector);
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);
        vm.stopPrank();
    }

    function test_RevertWhen_Stake_InvalidAmount() public {
        vm.deal(address(identityRegistry), 1 ether);
        vm.prank(address(identityRegistry));
        vm.expectRevert(StakingManager.InvalidAmount.selector);
        stakingManager.stake{value: 0.05 ether}(1);
    }

    function test_Unstake() public {
        uint256 agentId = 1;

        vm.deal(address(identityRegistry), 1 ether);
        vm.startPrank(address(identityRegistry));
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        uint256 balanceBefore = address(alice).balance;
        stakingManager.unstake(alice, agentId);
        uint256 balanceAfter = address(alice).balance;

        assertEq(balanceAfter - balanceBefore, STAKE_AMOUNT);
        (uint256 stakedAmount,) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, 0);
        vm.stopPrank();
    }

    function test_RevertWhen_Unstake_NotIdentityRegistry() public {
        vm.prank(alice);
        vm.expectRevert(StakingManager.Unauthorized.selector);
        stakingManager.unstake(alice, 1);
    }

    function test_RevertWhen_Unstake_NotStaked() public {
        vm.prank(address(identityRegistry));
        vm.expectRevert(StakingManager.NotStaked.selector);
        stakingManager.unstake(alice, 1);
    }

    function test_CheckAndSlash_ShouldSlash() public {
        uint256 agentId = 1;

        // Stake first
        vm.deal(address(identityRegistry), 1 ether);
        vm.prank(address(identityRegistry));
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        // Call checkAndSlash with bad reputation (-60) and 5 feedbacks
        vm.prank(address(reputationRegistry));
        stakingManager.checkAndSlash(agentId, -60e18, 5);

        // Verify slashing occurred
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT / 2); // 50% slashed
        assertTrue(isSlashed);
    }

    function test_CheckAndSlash_ShouldNotSlash_InsufficientFeedback() public {
        uint256 agentId = 1;

        vm.deal(address(identityRegistry), 1 ether);
        vm.prank(address(identityRegistry));
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        // Call with only 4 feedbacks (need 5)
        vm.prank(address(reputationRegistry));
        stakingManager.checkAndSlash(agentId, -60e18, 4);

        // Verify no slashing
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    function test_CheckAndSlash_ShouldNotSlash_ReputationAboveThreshold() public {
        uint256 agentId = 1;

        vm.deal(address(identityRegistry), 1 ether);
        vm.prank(address(identityRegistry));
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        // Call with good reputation (-40)
        vm.prank(address(reputationRegistry));
        stakingManager.checkAndSlash(agentId, -40e18, 5);

        // Verify no slashing
        (uint256 stakedAmount, bool isSlashed) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAmount, STAKE_AMOUNT);
        assertFalse(isSlashed);
    }

    function test_CheckAndSlash_ShouldNotSlash_AlreadySlashed() public {
        uint256 agentId = 1;

        vm.deal(address(identityRegistry), 1 ether);
        vm.prank(address(identityRegistry));
        stakingManager.stake{value: STAKE_AMOUNT}(agentId);

        // First slash
        vm.prank(address(reputationRegistry));
        stakingManager.checkAndSlash(agentId, -60e18, 5);

        (uint256 stakedAfterFirstSlash,) = stakingManager.getStakeInfo(agentId);

        // Try to slash again
        vm.prank(address(reputationRegistry));
        stakingManager.checkAndSlash(agentId, -60e18, 6);

        // Verify no additional slashing
        (uint256 stakedAfterSecondSlash,) = stakingManager.getStakeInfo(agentId);
        assertEq(stakedAfterSecondSlash, stakedAfterFirstSlash);
    }

    function test_RevertWhen_CheckAndSlash_NotReputationRegistry() public {
        vm.prank(alice);
        vm.expectRevert(StakingManager.Unauthorized.selector);
        stakingManager.checkAndSlash(1, -60e18, 5);
    }

    function test_CheckAndSlash_NoStake() public {
        // Should not revert, just do nothing
        vm.prank(address(reputationRegistry));
        stakingManager.checkAndSlash(1, -60e18, 5);

        (uint256 stakedAmount,) = stakingManager.getStakeInfo(1);
        assertEq(stakedAmount, 0);
    }
}
