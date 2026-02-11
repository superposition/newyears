// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC8004Identity
 * @notice Interface for ERC-8004 Trustless Agent Identity Registry
 * @dev Extends ERC-721 to provide on-chain identity for AI agents
 */
interface IERC8004Identity {
    /**
     * @notice Metadata entry structure
     * @param key Metadata key
     * @param value Metadata value (arbitrary bytes)
     */
    struct MetadataEntry {
        string key;
        bytes value;
    }

    /**
     * @notice Emitted when a new agent is registered
     * @param agentId The token ID of the registered agent
     * @param owner The owner address of the agent
     * @param agentURI The URI pointing to agent metadata
     */
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string agentURI);

    /**
     * @notice Emitted when an agent is deregistered
     * @param agentId The token ID of the deregistered agent
     * @param owner The owner address of the agent
     */
    event AgentDeregistered(uint256 indexed agentId, address indexed owner);

    /**
     * @notice Emitted when agent URI is updated
     * @param agentId The token ID of the agent
     * @param newURI The new URI
     */
    event AgentURIUpdated(uint256 indexed agentId, string newURI);

    /**
     * @notice Emitted when agent metadata is updated
     * @param agentId The token ID of the agent
     * @param key The metadata key
     * @param value The metadata value
     */
    event AgentMetadataUpdated(uint256 indexed agentId, string key, bytes value);

    /**
     * @notice Emitted when agent wallet is set
     * @param agentId The token ID of the agent
     * @param agentWallet The wallet address that can act on behalf of the agent
     */
    event AgentWalletSet(uint256 indexed agentId, address indexed agentWallet);

    /**
     * @notice Register a new agent
     * @param agentURI URI pointing to agent metadata (e.g., IPFS hash)
     * @param metadata Initial metadata entries
     * @return agentId The newly minted agent token ID
     */
    function register(string calldata agentURI, MetadataEntry[] calldata metadata)
        external
        returns (uint256 agentId);

    /**
     * @notice Deregister an agent (burns the NFT)
     * @param agentId The token ID of the agent to deregister
     */
    function deregister(uint256 agentId) external;

    /**
     * @notice Set or update the agent URI
     * @param agentId The token ID of the agent
     * @param newURI The new URI
     */
    function setAgentURI(uint256 agentId, string calldata newURI) external;

    /**
     * @notice Set or update agent metadata
     * @param agentId The token ID of the agent
     * @param key The metadata key
     * @param value The metadata value
     */
    function setMetadata(uint256 agentId, string calldata key, bytes calldata value) external;

    /**
     * @notice Set the agent wallet address via EIP-712 signature
     * @param agentId The token ID of the agent
     * @param agentWallet The wallet address to set
     * @param deadline Signature expiration timestamp
     * @param signature EIP-712 signature from the agent wallet
     */
    function setAgentWallet(uint256 agentId, address agentWallet, uint256 deadline, bytes calldata signature)
        external;

    /**
     * @notice Get the agent URI
     * @param agentId The token ID of the agent
     * @return The agent URI
     */
    function getAgentURI(uint256 agentId) external view returns (string memory);

    /**
     * @notice Get agent metadata value
     * @param agentId The token ID of the agent
     * @param key The metadata key
     * @return The metadata value
     */
    function getMetadata(uint256 agentId, string calldata key) external view returns (bytes memory);

    /**
     * @notice Get the agent wallet address
     * @param agentId The token ID of the agent
     * @return The agent wallet address (address(0) if not set)
     */
    function getAgentWallet(uint256 agentId) external view returns (address);

    /**
     * @notice Check if an agent exists
     * @param agentId The token ID to check
     * @return True if the agent exists
     */
    function exists(uint256 agentId) external view returns (bool);
}
