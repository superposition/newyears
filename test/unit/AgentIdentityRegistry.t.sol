// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {AgentIdentityRegistry} from "../../src/AgentIdentityRegistry.sol";
import {IERC8004Identity} from "../../src/interfaces/IERC8004Identity.sol";

contract AgentIdentityRegistryTest is TestHelper {
    function test_Register() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        assertEq(identityRegistry.ownerOf(agentId), alice);
        assertEq(identityRegistry.getAgentURI(agentId), "ipfs://agent1");
        assertTrue(identityRegistry.exists(agentId));
        assertEq(identityRegistry.totalSupply(), 1);
    }

    function test_Register_WithMetadata() public {
        IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](2);
        metadata[0] = IERC8004Identity.MetadataEntry({key: "name", value: abi.encode("Alice Agent")});
        metadata[1] = IERC8004Identity.MetadataEntry({key: "version", value: abi.encode("1.0.0")});

        uint256 agentId = registerAgentWithMetadata(alice, "ipfs://agent1", metadata);

        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "name"), (string)), "Alice Agent");
        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "version"), (string)), "1.0.0");
    }

    function test_RevertWhen_Register_InsufficientValue() public {
        vm.startPrank(alice);
        IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](0);
        vm.expectRevert();
        identityRegistry.register("ipfs://agent1", metadata);
        vm.stopPrank();
    }

    function test_Deregister() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint256 balanceBefore = address(alice).balance;

        vm.prank(alice);
        identityRegistry.deregister(agentId);

        uint256 balanceAfter = address(alice).balance;

        // Should refund stake
        assertEq(balanceAfter - balanceBefore, STAKE_AMOUNT);
        assertFalse(identityRegistry.exists(agentId));
        assertEq(identityRegistry.totalSupply(), 0);
    }

    function test_RevertWhen_Deregister_NotOwner() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        vm.expectRevert(AgentIdentityRegistry.NotAgentOwner.selector);
        identityRegistry.deregister(agentId);
    }

    function test_SetAgentURI() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(alice);
        identityRegistry.setAgentURI(agentId, "ipfs://agent1-updated");

        assertEq(identityRegistry.getAgentURI(agentId), "ipfs://agent1-updated");
    }

    function test_RevertWhen_SetAgentURI_NotOwner() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        vm.expectRevert(AgentIdentityRegistry.NotAgentOwner.selector);
        identityRegistry.setAgentURI(agentId, "ipfs://agent1-updated");
    }

    function test_SetMetadata() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(alice);
        identityRegistry.setMetadata(agentId, "version", abi.encode("2.0.0"));

        assertEq(abi.decode(identityRegistry.getMetadata(agentId, "version"), (string)), "2.0.0");
    }

    function test_RevertWhen_SetMetadata_NotOwner() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        vm.prank(bob);
        vm.expectRevert(AgentIdentityRegistry.NotAgentOwner.selector);
        identityRegistry.setMetadata(agentId, "version", abi.encode("2.0.0"));
    }

    function test_SetAgentWallet() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Create agent wallet keypair
        uint256 agentWalletPrivateKey = 0x1234;
        address agentWallet = vm.addr(agentWalletPrivateKey);

        uint256 deadline = block.timestamp + 1 hours;

        // Compute EIP-712 digest
        bytes32 domainSeparator = identityRegistry.getDomainSeparator();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SetAgentWallet(uint256 agentId,address agentWallet,uint256 deadline)"),
                agentId,
                agentWallet,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // Sign with agent wallet
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(agentWalletPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Set agent wallet
        vm.prank(alice);
        identityRegistry.setAgentWallet(agentId, agentWallet, deadline, signature);

        assertEq(identityRegistry.getAgentWallet(agentId), agentWallet);
    }

    function test_RevertWhen_SetAgentWallet_InvalidSignature() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        address agentWallet = address(0x999);
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory invalidSignature = new bytes(65);

        vm.prank(alice);
        // ECDSA library throws ECDSAInvalidSignature for invalid signatures
        vm.expectRevert();
        identityRegistry.setAgentWallet(agentId, agentWallet, deadline, invalidSignature);
    }

    function test_RevertWhen_SetAgentWallet_ExpiredSignature() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        uint256 agentWalletPrivateKey = 0x1234;
        address agentWallet = vm.addr(agentWalletPrivateKey);

        uint256 deadline = block.timestamp - 1; // Expired

        bytes32 domainSeparator = identityRegistry.getDomainSeparator();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SetAgentWallet(uint256 agentId,address agentWallet,uint256 deadline)"),
                agentId,
                agentWallet,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(agentWalletPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(alice);
        vm.expectRevert(AgentIdentityRegistry.InvalidSignature.selector);
        identityRegistry.setAgentWallet(agentId, agentWallet, deadline, signature);
    }

    function test_TransferClearsAgentWallet() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        // Set agent wallet
        uint256 agentWalletPrivateKey = 0x1234;
        address agentWallet = vm.addr(agentWalletPrivateKey);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 domainSeparator = identityRegistry.getDomainSeparator();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SetAgentWallet(uint256 agentId,address agentWallet,uint256 deadline)"),
                agentId,
                agentWallet,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(agentWalletPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(alice);
        identityRegistry.setAgentWallet(agentId, agentWallet, deadline, signature);

        assertEq(identityRegistry.getAgentWallet(agentId), agentWallet);

        // Transfer to bob
        vm.prank(alice);
        identityRegistry.transferFrom(alice, bob, agentId);

        // Agent wallet should be cleared
        assertEq(identityRegistry.getAgentWallet(agentId), address(0));
    }

    function test_GetAgentURI_NonExistent() public {
        vm.expectRevert();
        identityRegistry.getAgentURI(999);
    }

    function test_GetMetadata_NonExistent() public {
        vm.expectRevert(AgentIdentityRegistry.AgentNotFound.selector);
        identityRegistry.getMetadata(999, "key");
    }

    function test_GetAgentWallet_NonExistent() public {
        vm.expectRevert(AgentIdentityRegistry.AgentNotFound.selector);
        identityRegistry.getAgentWallet(999);
    }

    function test_Enumerable() public {
        registerAgent(alice, "ipfs://agent1");
        registerAgent(alice, "ipfs://agent2");
        registerAgent(bob, "ipfs://agent3");

        assertEq(identityRegistry.totalSupply(), 3);
        assertEq(identityRegistry.balanceOf(alice), 2);
        assertEq(identityRegistry.balanceOf(bob), 1);
        assertEq(identityRegistry.tokenOfOwnerByIndex(alice, 0), 1);
        assertEq(identityRegistry.tokenOfOwnerByIndex(alice, 1), 2);
        assertEq(identityRegistry.tokenByIndex(0), 1);
        assertEq(identityRegistry.tokenByIndex(1), 2);
        assertEq(identityRegistry.tokenByIndex(2), 3);
    }
}
