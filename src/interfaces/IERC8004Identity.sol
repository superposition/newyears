// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC8004Identity
 * @notice Interface for ERC-8004 Trustless Agent Identity Registry
 * @dev Extends ERC-721 to provide on-chain identity for AI agents
 */
interface IERC8004Identity {
    struct MetadataEntry {
        string metadataKey;
        bytes metadataValue;
    }

    // ── Spec Events ──

    event Registered(uint256 indexed agentId, string agentURI, address indexed owner);

    event MetadataSet(
        uint256 indexed agentId,
        string indexed indexedMetadataKey,
        string metadataKey,
        bytes metadataValue
    );

    event URIUpdated(uint256 indexed agentId, string newURI, address indexed updatedBy);

    // ── Custom Extension Events (PLASMA staking) ──

    event AgentDeregistered(uint256 indexed agentId, address indexed owner);

    // ── Registration (all payable for PLASMA staking) ──

    function register() external payable returns (uint256 agentId);

    function register(string calldata agentURI) external payable returns (uint256 agentId);

    function register(string calldata agentURI, MetadataEntry[] calldata metadata)
        external
        payable
        returns (uint256 agentId);

    // ── Custom Extension (PLASMA unstaking) ──

    function deregister(uint256 agentId) external;

    // ── URI ──

    function setAgentURI(uint256 agentId, string calldata newURI) external;

    // ── Metadata ──

    function getMetadata(uint256 agentId, string calldata metadataKey) external view returns (bytes memory);

    function setMetadata(uint256 agentId, string calldata metadataKey, bytes calldata metadataValue) external;

    // ── Agent Wallet ──

    function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature) external;

    function getAgentWallet(uint256 agentId) external view returns (address);

    function unsetAgentWallet(uint256 agentId) external;

    // ── Queries ──

    function isAuthorizedOrOwner(address spender, uint256 agentId) external view returns (bool);

    function exists(uint256 agentId) external view returns (bool);
}
