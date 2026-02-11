// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC8004Reputation} from "./interfaces/IERC8004Reputation.sol";
import {AgentIdentityRegistry} from "./AgentIdentityRegistry.sol";
import {StakingManager} from "./StakingManager.sol";

/**
 * @title ReputationRegistry
 * @notice Manages feedback and reputation for ERC-8004 agents with automatic slashing
 * @dev Implements structured feedback with revocation, aggregation, and slashing triggers
 */
contract ReputationRegistry is IERC8004Reputation {
    /// @notice Identity registry contract
    AgentIdentityRegistry public immutable identityRegistry;

    /// @notice Staking manager contract
    StakingManager public immutable stakingManager;

    /// @notice Mapping of agentId to array of feedback entries
    mapping(uint256 => Feedback[]) private _agentFeedback;

    /// @notice Mapping of agentId => feedbackIndex => response message
    mapping(uint256 => mapping(uint64 => string)) private _feedbackResponses;

    error AgentNotFound();
    error SelfFeedbackNotAllowed();
    error FeedbackNotFound();
    error Unauthorized();
    error AlreadyRevoked();
    error EmptyClientList();

    /**
     * @notice Constructor
     * @param _identityRegistry Address of the identity registry
     */
    constructor(address _identityRegistry) {
        if (_identityRegistry == address(0)) revert AgentNotFound();
        identityRegistry = AgentIdentityRegistry(_identityRegistry);
        stakingManager = identityRegistry.stakingManager();
    }

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
    ) external override returns (uint64 feedbackIndex) {
        // Check agent exists
        if (!identityRegistry.exists(agentId)) revert AgentNotFound();

        // Prevent self-feedback
        address agentOwner = identityRegistry.ownerOf(agentId);
        if (msg.sender == agentOwner) revert SelfFeedbackNotAllowed();

        // Create feedback entry
        feedbackIndex = uint64(_agentFeedback[agentId].length);
        Feedback memory feedback = Feedback({
            client: msg.sender,
            agent: agentId,
            value: value,
            valueDecimals: valueDecimals,
            tag1: tag1,
            tag2: tag2,
            comment: comment,
            timestamp: block.timestamp,
            isRevoked: false,
            feedbackIndex: feedbackIndex
        });

        _agentFeedback[agentId].push(feedback);

        emit FeedbackGiven(agentId, msg.sender, feedbackIndex, value, tag1, tag2);

        // Check and potentially slash stake based on new average reputation
        _checkAndSlash(agentId);
    }

    /**
     * @notice Revoke previously submitted feedback
     * @param agentId The agent ID
     * @param feedbackIndex The index of the feedback to revoke
     */
    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external override {
        if (feedbackIndex >= _agentFeedback[agentId].length) revert FeedbackNotFound();

        Feedback storage feedback = _agentFeedback[agentId][feedbackIndex];

        // Only original submitter can revoke
        if (feedback.client != msg.sender) revert Unauthorized();
        if (feedback.isRevoked) revert AlreadyRevoked();

        feedback.isRevoked = true;

        emit FeedbackRevoked(agentId, msg.sender, feedbackIndex);

        // Recheck slashing after revocation (reputation might improve)
        _checkAndSlash(agentId);
    }

    /**
     * @notice Agent owner responds to feedback
     * @param agentId The agent ID
     * @param feedbackIndex The feedback index
     * @param response The response message
     */
    function respondToFeedback(uint256 agentId, uint64 feedbackIndex, string calldata response) external override {
        if (!identityRegistry.exists(agentId)) revert AgentNotFound();
        if (feedbackIndex >= _agentFeedback[agentId].length) revert FeedbackNotFound();

        // Only agent owner can respond
        address agentOwner = identityRegistry.ownerOf(agentId);
        if (msg.sender != agentOwner) revert Unauthorized();

        _feedbackResponses[agentId][feedbackIndex] = response;

        emit FeedbackResponse(agentId, feedbackIndex, response);
    }

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
        override
        returns (ReputationSummary memory summary)
    {
        Feedback[] storage feedbacks = _agentFeedback[agentId];

        // Filter flags
        bool filterByClient = clients.length > 0;
        bool filterByTag1 = bytes(tag1).length > 0;
        bool filterByTag2 = bytes(tag2).length > 0;

        // Aggregate feedback
        int256 sum = 0;
        int128 min = type(int128).max;
        int128 max = type(int128).min;
        uint256 count = 0;
        uint8 decimals = 0;

        for (uint256 i = 0; i < feedbacks.length; i++) {
            Feedback storage fb = feedbacks[i];

            // Skip revoked feedback
            if (fb.isRevoked) continue;

            // Apply client filter
            if (filterByClient) {
                bool matchesClient = false;
                for (uint256 j = 0; j < clients.length; j++) {
                    if (fb.client == clients[j]) {
                        matchesClient = true;
                        break;
                    }
                }
                if (!matchesClient) continue;
            }

            // Apply tag filters
            if (filterByTag1 && keccak256(bytes(fb.tag1)) != keccak256(bytes(tag1))) continue;
            if (filterByTag2 && keccak256(bytes(fb.tag2)) != keccak256(bytes(tag2))) continue;

            // Accumulate
            sum += int256(fb.value);
            if (fb.value < min) min = fb.value;
            if (fb.value > max) max = fb.value;
            count++;

            // Use first feedback's decimals as reference
            if (count == 1) decimals = fb.valueDecimals;
        }

        // Compute average
        int128 average = count > 0 ? int128(sum / int256(count)) : int128(0);

        summary = ReputationSummary({
            agentId: agentId,
            totalCount: count,
            averageValue: average,
            valueDecimals: decimals,
            minValue: count > 0 ? min : int128(0),
            maxValue: count > 0 ? max : int128(0)
        });
    }

    /**
     * @notice Get specific feedback entry
     * @param agentId The agent ID
     * @param feedbackIndex The feedback index
     * @return The feedback entry
     */
    function getFeedback(uint256 agentId, uint64 feedbackIndex) external view override returns (Feedback memory) {
        if (feedbackIndex >= _agentFeedback[agentId].length) revert FeedbackNotFound();
        return _agentFeedback[agentId][feedbackIndex];
    }

    /**
     * @notice Get all feedback for an agent
     * @param agentId The agent ID
     * @param includeRevoked Whether to include revoked feedback
     * @return Array of feedback entries
     */
    function getAllFeedback(uint256 agentId, bool includeRevoked)
        external
        view
        override
        returns (Feedback[] memory)
    {
        Feedback[] storage feedbacks = _agentFeedback[agentId];

        if (includeRevoked) {
            return feedbacks;
        }

        // Count non-revoked
        uint256 count = 0;
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (!feedbacks[i].isRevoked) count++;
        }

        // Build result array
        Feedback[] memory result = new Feedback[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (!feedbacks[i].isRevoked) {
                result[index++] = feedbacks[i];
            }
        }

        return result;
    }

    /**
     * @notice Get total number of feedback entries for an agent
     * @param agentId The agent ID
     * @return Total feedback count
     */
    function getFeedbackCount(uint256 agentId) external view override returns (uint256) {
        return _agentFeedback[agentId].length;
    }

    /**
     * @notice Get feedback response from agent owner
     * @param agentId The agent ID
     * @param feedbackIndex The feedback index
     * @return The response message
     */
    function getFeedbackResponse(uint256 agentId, uint64 feedbackIndex) external view returns (string memory) {
        return _feedbackResponses[agentId][feedbackIndex];
    }

    /**
     * @dev Internal function to check reputation and trigger slashing
     * @param agentId The agent ID to check
     */
    function _checkAndSlash(uint256 agentId) internal {
        Feedback[] storage feedbacks = _agentFeedback[agentId];

        // Count non-revoked feedback
        uint256 count = 0;
        int256 sum = 0;

        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (!feedbacks[i].isRevoked) {
                sum += int256(feedbacks[i].value);
                count++;
            }
        }

        // Only trigger slashing check if there's enough feedback
        if (count >= 5) {
            // Compute average (scale to 1e18 for precision)
            int256 average = (sum * 1e18) / int256(count);

            // Call staking manager to check and slash
            stakingManager.checkAndSlash(agentId, average, count);
        }
    }
}
