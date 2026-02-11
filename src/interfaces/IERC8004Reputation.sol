// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC8004Reputation
 * @notice Interface for ERC-8004 Agent Reputation Registry
 * @dev Manages structured feedback with revocation and aggregation
 */
interface IERC8004Reputation {
    /**
     * @notice Feedback entry structure
     * @param client Address of the feedback submitter
     * @param agent Agent ID receiving the feedback
     * @param value Feedback value (int128 for flexibility)
     * @param valueDecimals Decimal places for the value
     * @param tag1 Primary tag for categorization
     * @param tag2 Secondary tag for categorization
     * @param comment Optional comment or URI
     * @param timestamp When the feedback was submitted
     * @param isRevoked Whether this feedback has been revoked
     * @param feedbackIndex Index of this feedback for the agent
     */
    struct Feedback {
        address client;
        uint256 agent;
        int128 value;
        uint8 valueDecimals;
        string tag1;
        string tag2;
        string comment;
        uint256 timestamp;
        bool isRevoked;
        uint64 feedbackIndex;
    }

    /**
     * @notice Aggregated reputation summary
     * @param agentId The agent ID
     * @param totalCount Total number of non-revoked feedback entries
     * @param averageValue Average feedback value
     * @param valueDecimals Decimal places for the average
     * @param minValue Minimum feedback value
     * @param maxValue Maximum feedback value
     */
    struct ReputationSummary {
        uint256 agentId;
        uint256 totalCount;
        int128 averageValue;
        uint8 valueDecimals;
        int128 minValue;
        int128 maxValue;
    }

    /**
     * @notice Emitted when feedback is submitted
     * @param agent The agent ID
     * @param client The feedback submitter
     * @param feedbackIndex The index of this feedback
     * @param value The feedback value
     * @param tag1 Primary tag
     * @param tag2 Secondary tag
     */
    event FeedbackGiven(
        uint256 indexed agent,
        address indexed client,
        uint64 feedbackIndex,
        int128 value,
        string tag1,
        string tag2
    );

    /**
     * @notice Emitted when feedback is revoked
     * @param agent The agent ID
     * @param client The feedback submitter
     * @param feedbackIndex The index of the revoked feedback
     */
    event FeedbackRevoked(uint256 indexed agent, address indexed client, uint64 feedbackIndex);

    /**
     * @notice Emitted when an agent responds to feedback
     * @param agent The agent ID
     * @param feedbackIndex The feedback index being responded to
     * @param response The response message
     */
    event FeedbackResponse(uint256 indexed agent, uint64 feedbackIndex, string response);

    /**
     * @notice Submit feedback for an agent
     * @param agentId The agent ID
     * @param value The feedback value (can be negative)
     * @param valueDecimals Decimal places for the value
     * @param tag1 Primary tag for categorization
     * @param tag2 Secondary tag for categorization
     * @param comment Optional comment or URI
     * @return feedbackIndex The index of the submitted feedback
     */
    function giveFeedback(
        uint256 agentId,
        int128 value,
        uint8 valueDecimals,
        string calldata tag1,
        string calldata tag2,
        string calldata comment
    ) external returns (uint64 feedbackIndex);

    /**
     * @notice Revoke previously submitted feedback
     * @param agentId The agent ID
     * @param feedbackIndex The index of the feedback to revoke
     */
    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external;

    /**
     * @notice Agent owner responds to feedback
     * @param agentId The agent ID
     * @param feedbackIndex The feedback index
     * @param response The response message
     */
    function respondToFeedback(uint256 agentId, uint64 feedbackIndex, string calldata response) external;

    /**
     * @notice Get reputation summary for an agent
     * @param agentId The agent ID
     * @param clients Array of client addresses to filter by (empty for all)
     * @param tag1 Primary tag filter (empty for all)
     * @param tag2 Secondary tag filter (empty for all)
     * @return summary The aggregated reputation summary
     */
    function getSummary(uint256 agentId, address[] calldata clients, string calldata tag1, string calldata tag2)
        external
        view
        returns (ReputationSummary memory summary);

    /**
     * @notice Get specific feedback entry
     * @param agentId The agent ID
     * @param feedbackIndex The feedback index
     * @return The feedback entry
     */
    function getFeedback(uint256 agentId, uint64 feedbackIndex) external view returns (Feedback memory);

    /**
     * @notice Get all feedback for an agent
     * @param agentId The agent ID
     * @param includeRevoked Whether to include revoked feedback
     * @return Array of feedback entries
     */
    function getAllFeedback(uint256 agentId, bool includeRevoked) external view returns (Feedback[] memory);

    /**
     * @notice Get total number of feedback entries for an agent
     * @param agentId The agent ID
     * @return Total feedback count
     */
    function getFeedbackCount(uint256 agentId) external view returns (uint256);
}
