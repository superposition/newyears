// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC8004Reputation
 * @notice Interface for ERC-8004 Agent Reputation Registry
 * @dev Manages structured feedback with revocation, responses, and aggregation
 */
interface IERC8004Reputation {
    /// @notice On-chain feedback storage (5 fields per spec)
    struct Feedback {
        int128 value;
        uint8 valueDecimals;
        bool isRevoked;
        string tag1;
        string tag2;
    }

    // ── Spec Events ──

    event NewFeedback(
        uint256 indexed agentId,
        address indexed clientAddress,
        uint64 feedbackIndex,
        int128 value,
        uint8 valueDecimals,
        string indexed indexedTag1,
        string tag1,
        string tag2,
        string endpoint,
        string feedbackURI,
        bytes32 feedbackHash
    );

    event FeedbackRevoked(uint256 indexed agentId, address indexed clientAddress, uint64 indexed feedbackIndex);

    event ResponseAppended(
        uint256 indexed agentId,
        address indexed clientAddress,
        uint64 feedbackIndex,
        address indexed responder,
        string responseURI,
        bytes32 responseHash
    );

    // ── Functions ──

    function giveFeedback(
        uint256 agentId,
        int128 value,
        uint8 valueDecimals,
        string calldata tag1,
        string calldata tag2,
        string calldata endpoint,
        string calldata feedbackURI,
        bytes32 feedbackHash
    ) external returns (uint64 feedbackIndex);

    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external;

    function appendResponse(
        uint256 agentId,
        address clientAddress,
        uint64 feedbackIndex,
        string calldata responseURI,
        bytes32 responseHash
    ) external;

    function getSummary(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2)
        external
        view
        returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals);

    function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex)
        external
        view
        returns (int128 value, uint8 valueDecimals, string memory tag1, string memory tag2, bool isRevoked);

    function readAllFeedback(
        uint256 agentId,
        address[] calldata clientAddresses,
        string calldata tag1,
        string calldata tag2,
        bool includeRevoked
    )
        external
        view
        returns (
            uint256[] memory agentIds,
            address[] memory clients,
            uint64[] memory feedbackIndexes,
            int128[] memory values,
            uint8[] memory valueDecimalsArr,
            string[] memory tag1s,
            string[] memory tag2s
        );

    function getResponseCount(
        uint256 agentId,
        address clientAddress,
        uint64 feedbackIndex,
        address[] calldata responders
    ) external view returns (uint64);

    function getClients(uint256 agentId) external view returns (address[] memory);

    function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64);

    function getIdentityRegistry() external view returns (address);
}
