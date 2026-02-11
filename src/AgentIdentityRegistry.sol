// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC8004Identity} from "./interfaces/IERC8004Identity.sol";
import {SignatureVerifier} from "./libraries/SignatureVerifier.sol";
import {StakingManager} from "./StakingManager.sol";

/**
 * @title AgentIdentityRegistry
 * @notice ERC-721 based identity registry for trustless AI agents with PLASMA staking requirement
 * @dev Implements ERC-8004 Identity interface with custom staking mechanism
 */
contract AgentIdentityRegistry is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, IERC8004Identity {
    /// @notice Staking manager contract
    StakingManager public immutable stakingManager;

    /// @notice Counter for agent IDs
    uint256 private _nextAgentId;

    /// @notice Mapping of agentId to agentWallet address
    mapping(uint256 => address) private _agentWallets;

    /// @notice Mapping of agentId to metadata (key => value)
    mapping(uint256 => mapping(string => bytes)) private _agentMetadata;

    /// @notice EIP-712 domain separator
    bytes32 private immutable _domainSeparator;

    /// @notice Contract name for EIP-712
    string private constant NAME = "AgentIdentityRegistry";

    /// @notice Contract version for EIP-712
    string private constant VERSION = "1";

    error NotAgentOwner();
    error AgentNotFound();
    error InvalidSignature();
    error SignatureExpired();
    error InvalidAddress();

    /**
     * @notice Constructor
     * @param _stakingManager Address of the staking manager contract
     */
    constructor(address payable _stakingManager) ERC721("ERC8004 Agent Identity", "AGENT") Ownable(msg.sender) {
        if (_stakingManager == address(0)) revert InvalidAddress();
        stakingManager = StakingManager(_stakingManager);

        // Compute EIP-712 domain separator
        _domainSeparator = SignatureVerifier.computeDomainSeparator(NAME, VERSION, block.chainid, address(this));

        // Start agent IDs at 1
        _nextAgentId = 1;
    }

    /**
     * @notice Register a new agent with PLASMA staking
     * @param agentURI URI pointing to agent metadata
     * @param metadata Initial metadata entries
     * @return agentId The newly minted agent token ID
     */
    function register(string calldata agentURI, MetadataEntry[] calldata metadata)
        external
        payable
        override
        returns (uint256 agentId)
    {
        agentId = _nextAgentId++;

        // Stake native PLASMA (will revert if insufficient value)
        stakingManager.stake{value: msg.value}(agentId);

        // Mint NFT to caller
        _safeMint(msg.sender, agentId);
        _setTokenURI(agentId, agentURI);

        // Set initial metadata
        for (uint256 i = 0; i < metadata.length; i++) {
            _agentMetadata[agentId][metadata[i].key] = metadata[i].value;
            emit AgentMetadataUpdated(agentId, metadata[i].key, metadata[i].value);
        }

        emit AgentRegistered(agentId, msg.sender, agentURI);
    }

    /**
     * @notice Deregister an agent (burn NFT and refund stake)
     * @param agentId The token ID of the agent to deregister
     */
    function deregister(uint256 agentId) external override {
        address owner = ownerOf(agentId);
        if (msg.sender != owner) revert NotAgentOwner();

        // Refund stake to owner
        stakingManager.unstake(owner, agentId);

        // Burn the NFT
        _burn(agentId);

        emit AgentDeregistered(agentId, owner);
    }

    /**
     * @notice Set or update the agent URI
     * @param agentId The token ID of the agent
     * @param newURI The new URI
     */
    function setAgentURI(uint256 agentId, string calldata newURI) external override {
        if (msg.sender != ownerOf(agentId)) revert NotAgentOwner();
        _setTokenURI(agentId, newURI);
        emit AgentURIUpdated(agentId, newURI);
    }

    /**
     * @notice Set or update agent metadata
     * @param agentId The token ID of the agent
     * @param key The metadata key
     * @param value The metadata value
     */
    function setMetadata(uint256 agentId, string calldata key, bytes calldata value) external override {
        if (msg.sender != ownerOf(agentId)) revert NotAgentOwner();
        _agentMetadata[agentId][key] = value;
        emit AgentMetadataUpdated(agentId, key, value);
    }

    /**
     * @notice Set the agent wallet address via EIP-712 signature
     * @param agentId The token ID of the agent
     * @param agentWallet The wallet address to set
     * @param deadline Signature expiration timestamp
     * @param signature EIP-712 signature from the agent wallet
     */
    function setAgentWallet(uint256 agentId, address agentWallet, uint256 deadline, bytes calldata signature)
        external
        override
    {
        if (msg.sender != ownerOf(agentId)) revert NotAgentOwner();
        if (agentWallet == address(0)) revert InvalidAddress();

        // Verify signature
        bool isValid =
            SignatureVerifier.verifySetAgentWallet(_domainSeparator, agentId, agentWallet, deadline, signature);

        if (!isValid) revert InvalidSignature();

        _agentWallets[agentId] = agentWallet;
        emit AgentWalletSet(agentId, agentWallet);
    }

    /**
     * @notice Get the agent URI
     * @param agentId The token ID of the agent
     * @return The agent URI
     */
    function getAgentURI(uint256 agentId) external view override returns (string memory) {
        return tokenURI(agentId);
    }

    /**
     * @notice Get agent metadata value
     * @param agentId The token ID of the agent
     * @param key The metadata key
     * @return The metadata value
     */
    function getMetadata(uint256 agentId, string calldata key) external view override returns (bytes memory) {
        if (!_exists(agentId)) revert AgentNotFound();
        return _agentMetadata[agentId][key];
    }

    /**
     * @notice Get the agent wallet address
     * @param agentId The token ID of the agent
     * @return The agent wallet address (address(0) if not set)
     */
    function getAgentWallet(uint256 agentId) external view override returns (address) {
        if (!_exists(agentId)) revert AgentNotFound();
        return _agentWallets[agentId];
    }

    /**
     * @notice Check if an agent exists
     * @param agentId The token ID to check
     * @return True if the agent exists
     */
    function exists(uint256 agentId) external view override returns (bool) {
        return _exists(agentId);
    }

    /**
     * @notice Get EIP-712 domain separator
     * @return The domain separator
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparator;
    }

    /**
     * @dev Internal function to check if token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Override _update to clear agent wallet on transfer (per ERC-8004 spec)
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        address from = _ownerOf(tokenId);

        // Clear agent wallet on transfer (not on mint)
        if (from != address(0) && to != address(0)) {
            delete _agentWallets[tokenId];
        }

        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Override _increaseBalance for Enumerable
     */
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    /**
     * @dev Override tokenURI for URIStorage
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override supportsInterface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
