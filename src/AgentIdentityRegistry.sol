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
 * @notice ERC-8004 spec-compliant identity registry with PLASMA staking extension
 */
contract AgentIdentityRegistry is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, IERC8004Identity {
    StakingManager public immutable stakingManager;

    uint256 private _nextAgentId;

    /// @notice Metadata storage: agentId => metadataKey => metadataValue
    mapping(uint256 => mapping(string => bytes)) private _agentMetadata;

    bytes32 private immutable _domainSeparator;

    string private constant NAME = "ERC8004IdentityRegistry";
    string private constant VERSION = "1";

    string private constant RESERVED_AGENT_WALLET_KEY = "agentWallet";

    error NotAuthorized();
    error AgentNotFound();
    error InvalidSignature();
    error SignatureExpired();
    error InvalidAddress();
    error ReservedMetadataKey();
    error DeadlineTooFar();

    constructor(address payable _stakingManager) ERC721("ERC8004 Agent Identity", "AGENT") Ownable(msg.sender) {
        if (_stakingManager == address(0)) revert InvalidAddress();
        stakingManager = StakingManager(_stakingManager);
        _domainSeparator = SignatureVerifier.computeDomainSeparator(NAME, VERSION, block.chainid, address(this));
        _nextAgentId = 1;
    }

    // ── Registration Overloads ──

    /// @notice Bare registration (no URI, no metadata)
    function register() external payable override returns (uint256 agentId) {
        MetadataEntry[] memory empty = new MetadataEntry[](0);
        return _register("", empty);
    }

    /// @notice URI-only registration
    function register(string calldata agentURI) external payable override returns (uint256 agentId) {
        MetadataEntry[] memory empty = new MetadataEntry[](0);
        return _register(agentURI, empty);
    }

    /// @notice Full registration with URI and metadata
    function register(string calldata agentURI, MetadataEntry[] calldata metadata)
        external
        payable
        override
        returns (uint256 agentId)
    {
        return _register(agentURI, metadata);
    }

    function _register(string memory agentURI, MetadataEntry[] memory metadata) internal returns (uint256 agentId) {
        agentId = _nextAgentId++;

        // Stake native PLASMA
        stakingManager.stake{value: msg.value}(agentId);

        // Mint NFT
        _safeMint(msg.sender, agentId);
        if (bytes(agentURI).length > 0) {
            _setTokenURI(agentId, agentURI);
        }

        // Set initial metadata (reject reserved key)
        for (uint256 i = 0; i < metadata.length; i++) {
            if (keccak256(bytes(metadata[i].metadataKey)) == keccak256(bytes(RESERVED_AGENT_WALLET_KEY))) {
                revert ReservedMetadataKey();
            }
            _agentMetadata[agentId][metadata[i].metadataKey] = metadata[i].metadataValue;
            emit MetadataSet(agentId, metadata[i].metadataKey, metadata[i].metadataKey, metadata[i].metadataValue);
        }

        // Auto-set agentWallet to msg.sender
        _agentMetadata[agentId][RESERVED_AGENT_WALLET_KEY] = abi.encodePacked(msg.sender);
        emit MetadataSet(agentId, RESERVED_AGENT_WALLET_KEY, RESERVED_AGENT_WALLET_KEY, abi.encodePacked(msg.sender));

        emit Registered(agentId, agentURI, msg.sender);
    }

    // ── Deregister (custom PLASMA extension) ──

    function deregister(uint256 agentId) external override {
        address tokenOwner = ownerOf(agentId);
        if (msg.sender != tokenOwner) revert NotAuthorized();

        stakingManager.unstake(tokenOwner, agentId);
        _burn(agentId);

        emit AgentDeregistered(agentId, tokenOwner);
    }

    // ── URI ──

    function setAgentURI(uint256 agentId, string calldata newURI) external override {
        if (!_isAuthorizedOrOwner(msg.sender, agentId)) revert NotAuthorized();
        _setTokenURI(agentId, newURI);
        emit URIUpdated(agentId, newURI, msg.sender);
    }

    // ── Metadata ──

    function getMetadata(uint256 agentId, string calldata metadataKey) external view override returns (bytes memory) {
        if (!_exists(agentId)) revert AgentNotFound();
        return _agentMetadata[agentId][metadataKey];
    }

    function setMetadata(uint256 agentId, string calldata metadataKey, bytes calldata metadataValue)
        external
        override
    {
        if (!_isAuthorizedOrOwner(msg.sender, agentId)) revert NotAuthorized();
        if (keccak256(bytes(metadataKey)) == keccak256(bytes(RESERVED_AGENT_WALLET_KEY))) {
            revert ReservedMetadataKey();
        }
        _agentMetadata[agentId][metadataKey] = metadataValue;
        emit MetadataSet(agentId, metadataKey, metadataKey, metadataValue);
    }

    // ── Agent Wallet ──

    function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature)
        external
        override
    {
        if (!_isAuthorizedOrOwner(msg.sender, agentId)) revert NotAuthorized();
        if (newWallet == address(0)) revert InvalidAddress();

        // 5-minute deadline check
        if (deadline > block.timestamp + 5 minutes) revert DeadlineTooFar();

        address tokenOwner = ownerOf(agentId);
        bool isValid = SignatureVerifier.verifySetAgentWallet(
            _domainSeparator, agentId, newWallet, tokenOwner, deadline, signature
        );
        if (!isValid) revert InvalidSignature();

        _agentMetadata[agentId][RESERVED_AGENT_WALLET_KEY] = abi.encodePacked(newWallet);
        emit MetadataSet(
            agentId, RESERVED_AGENT_WALLET_KEY, RESERVED_AGENT_WALLET_KEY, abi.encodePacked(newWallet)
        );
    }

    function getAgentWallet(uint256 agentId) external view override returns (address) {
        if (!_exists(agentId)) revert AgentNotFound();
        bytes memory walletBytes = _agentMetadata[agentId][RESERVED_AGENT_WALLET_KEY];
        if (walletBytes.length == 0) return address(0);
        return address(bytes20(walletBytes));
    }

    function unsetAgentWallet(uint256 agentId) external override {
        if (!_isAuthorizedOrOwner(msg.sender, agentId)) revert NotAuthorized();
        delete _agentMetadata[agentId][RESERVED_AGENT_WALLET_KEY];
        emit MetadataSet(agentId, RESERVED_AGENT_WALLET_KEY, RESERVED_AGENT_WALLET_KEY, "");
    }

    // ── Queries ──

    function isAuthorizedOrOwner(address spender, uint256 agentId) external view override returns (bool) {
        return _isAuthorizedOrOwner(spender, agentId);
    }

    function exists(uint256 agentId) external view override returns (bool) {
        return _exists(agentId);
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparator;
    }

    function getAgentURI(uint256 agentId) external view returns (string memory) {
        return tokenURI(agentId);
    }

    // ── Internal ──

    function _isAuthorizedOrOwner(address spender, uint256 agentId) internal view returns (bool) {
        if (!_exists(agentId)) return false;
        address tokenOwner = ownerOf(agentId);
        return (spender == tokenOwner || isApprovedForAll(tokenOwner, spender) || getApproved(agentId) == spender);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /// @dev Clear agentWallet metadata on transfer (not on mint/burn)
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        address from = _ownerOf(tokenId);

        // Clear agentWallet on transfer (not mint, not burn)
        if (from != address(0) && to != address(0)) {
            delete _agentMetadata[tokenId][RESERVED_AGENT_WALLET_KEY];
            emit MetadataSet(tokenId, RESERVED_AGENT_WALLET_KEY, RESERVED_AGENT_WALLET_KEY, "");
        }

        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
