// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StakingManager} from "../src/StakingManager.sol";
import {AgentIdentityRegistry} from "../src/AgentIdentityRegistry.sol";
import {ReputationRegistry} from "../src/ReputationRegistry.sol";
import {ValidationRegistry} from "../src/ValidationRegistry.sol";
import {IERC8004Identity} from "../src/interfaces/IERC8004Identity.sol";

contract TestHelper is Test {
    StakingManager public stakingManager;
    AgentIdentityRegistry public identityRegistry;
    ReputationRegistry public reputationRegistry;
    ValidationRegistry public validationRegistry;

    address public deployer = address(0x1);
    address public alice = address(0x2);
    address public bob = address(0x3);
    address public charlie = address(0x4);
    address public validator1 = address(0x5);
    address public validator2 = address(0x6);

    uint256 public constant STAKE_AMOUNT = 0.1 ether;

    function setUp() public virtual {
        vm.startPrank(deployer);

        stakingManager = new StakingManager();
        identityRegistry = new AgentIdentityRegistry(payable(address(stakingManager)));
        reputationRegistry = new ReputationRegistry(address(identityRegistry));
        validationRegistry = new ValidationRegistry(address(identityRegistry));

        stakingManager.setIdentityRegistry(address(identityRegistry));
        stakingManager.setReputationRegistry(address(reputationRegistry));

        vm.stopPrank();

        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(charlie, 1000 ether);
        vm.deal(validator1, 1000 ether);
        vm.deal(validator2, 1000 ether);
        vm.deal(deployer, 1000 ether);
    }

    // Helper: Register an agent (full overload)
    function registerAgent(address user, string memory uri) internal returns (uint256 agentId) {
        vm.startPrank(user);
        IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](0);
        agentId = identityRegistry.register{value: STAKE_AMOUNT}(uri, metadata);
        vm.stopPrank();
    }

    // Helper: Register agent with metadata
    function registerAgentWithMetadata(
        address user,
        string memory uri,
        IERC8004Identity.MetadataEntry[] memory metadata
    ) internal returns (uint256 agentId) {
        vm.startPrank(user);
        agentId = identityRegistry.register{value: STAKE_AMOUNT}(uri, metadata);
        vm.stopPrank();
    }

    // Helper: Give feedback (8-param version)
    function giveFeedback(address user, uint256 agentId, int128 value, string memory tag1, string memory tag2)
        internal
        returns (uint64 feedbackIndex)
    {
        vm.startPrank(user);
        feedbackIndex = reputationRegistry.giveFeedback(agentId, value, 0, tag1, tag2, "", "", bytes32(0));
        vm.stopPrank();
    }

    // Helper: Request validation (4-param, no tag — tag is in response only)
    function requestValidation(address user, address validatorAddr, uint256 agentId, bytes32 requestHash)
        internal
    {
        vm.startPrank(user);
        validationRegistry.validationRequest(validatorAddr, agentId, "ipfs://validation", requestHash);
        vm.stopPrank();
    }

    // Helper: Submit validation response (5-param, with tag)
    function submitValidationResponse(address validatorAddr, bytes32 requestHash, uint8 score, string memory tag)
        internal
    {
        vm.startPrank(validatorAddr);
        validationRegistry.validationResponse(requestHash, score, "", bytes32(0), tag);
        vm.stopPrank();
    }

    // Helper: Append response to feedback
    function appendFeedbackResponse(
        address responder,
        uint256 agentId,
        address clientAddress,
        uint64 feedbackIndex
    ) internal {
        vm.startPrank(responder);
        reputationRegistry.appendResponse(agentId, clientAddress, feedbackIndex, "ipfs://response", bytes32(0));
        vm.stopPrank();
    }
}
