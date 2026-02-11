// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC8004Reputation} from "./interfaces/IERC8004Reputation.sol";
import {AgentIdentityRegistry} from "./AgentIdentityRegistry.sol";
import {StakingManager} from "./StakingManager.sol";

/**
 * @title ReputationRegistry
 * @notice ERC-8004 spec-compliant reputation registry with PLASMA slashing extension
 * @dev feedbackIndex is 1-based, per (agentId, clientAddress)
 */
contract ReputationRegistry is IERC8004Reputation {
    AgentIdentityRegistry public immutable identityRegistry;
    StakingManager public immutable stakingManager;

    /// @notice Feedback storage: agentId => clientAddress => feedbackIndex => Feedback
    mapping(uint256 => mapping(address => mapping(uint64 => Feedback))) private _feedback;

    /// @notice Last feedback index per (agentId, clientAddress)
    mapping(uint256 => mapping(address => uint64)) private _lastIndex;

    /// @notice Client list per agentId (for enumeration)
    mapping(uint256 => address[]) private _clients;
    mapping(uint256 => mapping(address => bool)) private _clientExists;

    /// @notice Response tracking: agentId => clientAddress => feedbackIndex => responder => responded
    mapping(uint256 => mapping(address => mapping(uint64 => mapping(address => bool)))) private _responderExists;
    /// @notice Count of unique responders per feedback
    mapping(uint256 => mapping(address => mapping(uint64 => uint64))) private _responseCount;

    int128 private constant MAX_VALUE = 1e38;
    int128 private constant MIN_VALUE = -1e38;

    error AgentNotFound();
    error SelfFeedbackNotAllowed();
    error FeedbackNotFound();
    error Unauthorized();
    error AlreadyRevoked();
    error ValueOutOfRange();
    error DecimalsTooHigh();

    constructor(address _identityRegistry) {
        if (_identityRegistry == address(0)) revert AgentNotFound();
        identityRegistry = AgentIdentityRegistry(_identityRegistry);
        stakingManager = identityRegistry.stakingManager();
    }

    function giveFeedback(
        uint256 agentId,
        int128 value,
        uint8 valueDecimals,
        string calldata tag1,
        string calldata tag2,
        string calldata endpoint,
        string calldata feedbackURI,
        bytes32 feedbackHash
    ) external override returns (uint64 feedbackIndex) {
        if (!identityRegistry.exists(agentId)) revert AgentNotFound();

        // Prevent self-feedback (owner, operator, or approved)
        if (identityRegistry.isAuthorizedOrOwner(msg.sender, agentId)) revert SelfFeedbackNotAllowed();

        // Validate
        if (valueDecimals > 18) revert DecimalsTooHigh();
        if (value > MAX_VALUE || value < MIN_VALUE) revert ValueOutOfRange();

        // Track client
        if (!_clientExists[agentId][msg.sender]) {
            _clients[agentId].push(msg.sender);
            _clientExists[agentId][msg.sender] = true;
        }

        // 1-based feedbackIndex
        feedbackIndex = _lastIndex[agentId][msg.sender] + 1;
        _lastIndex[agentId][msg.sender] = feedbackIndex;

        // Store feedback
        _feedback[agentId][msg.sender][feedbackIndex] = Feedback({
            value: value,
            valueDecimals: valueDecimals,
            isRevoked: false,
            tag1: tag1,
            tag2: tag2
        });

        emit NewFeedback(agentId, msg.sender, feedbackIndex, value, valueDecimals, tag1, tag1, tag2, endpoint, feedbackURI, feedbackHash);

        _checkAndSlash(agentId);
    }

    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external override {
        if (feedbackIndex == 0 || feedbackIndex > _lastIndex[agentId][msg.sender]) revert FeedbackNotFound();

        Feedback storage fb = _feedback[agentId][msg.sender][feedbackIndex];
        if (fb.isRevoked) revert AlreadyRevoked();

        fb.isRevoked = true;

        emit FeedbackRevoked(agentId, msg.sender, feedbackIndex);

        _checkAndSlash(agentId);
    }

    function appendResponse(
        uint256 agentId,
        address clientAddress,
        uint64 feedbackIndex,
        string calldata responseURI,
        bytes32 responseHash
    ) external override {
        if (feedbackIndex == 0 || feedbackIndex > _lastIndex[agentId][clientAddress]) revert FeedbackNotFound();

        if (!_responderExists[agentId][clientAddress][feedbackIndex][msg.sender]) {
            _responderExists[agentId][clientAddress][feedbackIndex][msg.sender] = true;
            _responseCount[agentId][clientAddress][feedbackIndex]++;
        }

        emit ResponseAppended(agentId, clientAddress, feedbackIndex, msg.sender, responseURI, responseHash);
    }

    function getSummary(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2)
        external
        view
        override
        returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals)
    {
        bool filterByClient = clientAddresses.length > 0;
        bool filterByTag1 = bytes(tag1).length > 0;
        bool filterByTag2 = bytes(tag2).length > 0;

        // Determine which clients to iterate
        address[] memory clients;
        if (filterByClient) {
            clients = clientAddresses;
        } else {
            clients = _clients[agentId];
        }

        // First pass: find mode decimals and count
        uint256[19] memory decimalCounts;
        uint256 totalCount = 0;

        for (uint256 c = 0; c < clients.length; c++) {
            address client = clients[c];
            uint64 last = _lastIndex[agentId][client];
            for (uint64 i = 1; i <= last; i++) {
                Feedback storage fb = _feedback[agentId][client][i];
                if (fb.isRevoked) continue;
                if (filterByTag1 && keccak256(bytes(fb.tag1)) != keccak256(bytes(tag1))) continue;
                if (filterByTag2 && keccak256(bytes(fb.tag2)) != keccak256(bytes(tag2))) continue;
                decimalCounts[fb.valueDecimals]++;
                totalCount++;
            }
        }

        if (totalCount == 0) return (0, 0, 0);

        // Find mode decimals
        uint8 modeDecimals = 0;
        uint256 maxCount = 0;
        for (uint8 d = 0; d <= 18; d++) {
            if (decimalCounts[d] > maxCount) {
                maxCount = decimalCounts[d];
                modeDecimals = d;
            }
        }

        // WAD normalization: normalize all to 18 decimals, sum, average, scale back
        int256 wadSum = 0;
        for (uint256 c = 0; c < clients.length; c++) {
            address client = clients[c];
            uint64 last = _lastIndex[agentId][client];
            for (uint64 i = 1; i <= last; i++) {
                Feedback storage fb = _feedback[agentId][client][i];
                if (fb.isRevoked) continue;
                if (filterByTag1 && keccak256(bytes(fb.tag1)) != keccak256(bytes(tag1))) continue;
                if (filterByTag2 && keccak256(bytes(fb.tag2)) != keccak256(bytes(tag2))) continue;
                // Normalize to 18 decimals
                int256 wadValue = int256(fb.value) * int256(10 ** (18 - fb.valueDecimals));
                wadSum += wadValue;
            }
        }

        // Average at WAD precision, then scale to mode decimals
        int256 wadAverage = wadSum / int256(totalCount);
        int256 scaledAverage = wadAverage / int256(10 ** (18 - modeDecimals));

        count = uint64(totalCount);
        summaryValue = int128(scaledAverage);
        summaryValueDecimals = modeDecimals;
    }

    function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex)
        external
        view
        override
        returns (int128 value, uint8 valueDecimals, string memory tag1, string memory tag2, bool isRevoked)
    {
        if (feedbackIndex == 0 || feedbackIndex > _lastIndex[agentId][clientAddress]) revert FeedbackNotFound();
        Feedback storage fb = _feedback[agentId][clientAddress][feedbackIndex];
        return (fb.value, fb.valueDecimals, fb.tag1, fb.tag2, fb.isRevoked);
    }

    function readAllFeedback(
        uint256 agentId,
        address[] calldata clientAddresses,
        string calldata tag1,
        string calldata tag2,
        bool includeRevoked
    )
        external
        view
        override
        returns (
            uint256[] memory agentIds,
            address[] memory clients,
            uint64[] memory feedbackIndexes,
            int128[] memory values,
            uint8[] memory valueDecimalsArr,
            string[] memory tag1s,
            string[] memory tag2s
        )
    {
        bool filterByClient = clientAddresses.length > 0;
        bool filterByTag1 = bytes(tag1).length > 0;
        bool filterByTag2 = bytes(tag2).length > 0;

        address[] memory clientList;
        if (filterByClient) {
            clientList = clientAddresses;
        } else {
            clientList = _clients[agentId];
        }

        // Count matching entries
        uint256 total = 0;
        for (uint256 c = 0; c < clientList.length; c++) {
            uint64 last = _lastIndex[agentId][clientList[c]];
            for (uint64 i = 1; i <= last; i++) {
                Feedback storage fb = _feedback[agentId][clientList[c]][i];
                if (!includeRevoked && fb.isRevoked) continue;
                if (filterByTag1 && keccak256(bytes(fb.tag1)) != keccak256(bytes(tag1))) continue;
                if (filterByTag2 && keccak256(bytes(fb.tag2)) != keccak256(bytes(tag2))) continue;
                total++;
            }
        }

        agentIds = new uint256[](total);
        clients = new address[](total);
        feedbackIndexes = new uint64[](total);
        values = new int128[](total);
        valueDecimalsArr = new uint8[](total);
        tag1s = new string[](total);
        tag2s = new string[](total);

        uint256 idx = 0;
        for (uint256 c = 0; c < clientList.length; c++) {
            address client = clientList[c];
            uint64 last = _lastIndex[agentId][client];
            for (uint64 i = 1; i <= last; i++) {
                Feedback storage fb = _feedback[agentId][client][i];
                if (!includeRevoked && fb.isRevoked) continue;
                if (filterByTag1 && keccak256(bytes(fb.tag1)) != keccak256(bytes(tag1))) continue;
                if (filterByTag2 && keccak256(bytes(fb.tag2)) != keccak256(bytes(tag2))) continue;
                agentIds[idx] = agentId;
                clients[idx] = client;
                feedbackIndexes[idx] = i;
                values[idx] = fb.value;
                valueDecimalsArr[idx] = fb.valueDecimals;
                tag1s[idx] = fb.tag1;
                tag2s[idx] = fb.tag2;
                idx++;
            }
        }
    }

    function getResponseCount(
        uint256 agentId,
        address clientAddress,
        uint64 feedbackIndex,
        address[] calldata responders
    ) external view override returns (uint64) {
        if (responders.length == 0) {
            return _responseCount[agentId][clientAddress][feedbackIndex];
        }
        uint64 cnt = 0;
        for (uint256 i = 0; i < responders.length; i++) {
            if (_responderExists[agentId][clientAddress][feedbackIndex][responders[i]]) {
                cnt++;
            }
        }
        return cnt;
    }

    function getClients(uint256 agentId) external view override returns (address[] memory) {
        return _clients[agentId];
    }

    function getLastIndex(uint256 agentId, address clientAddress) external view override returns (uint64) {
        return _lastIndex[agentId][clientAddress];
    }

    function getIdentityRegistry() external view override returns (address) {
        return address(identityRegistry);
    }

    // ── PLASMA Slashing Extension ──

    function _checkAndSlash(uint256 agentId) internal {
        address[] memory clients = _clients[agentId];

        uint256 nonRevokedCount = 0;
        int256 sum = 0;

        for (uint256 c = 0; c < clients.length; c++) {
            uint64 last = _lastIndex[agentId][clients[c]];
            for (uint64 i = 1; i <= last; i++) {
                Feedback storage fb = _feedback[agentId][clients[c]][i];
                if (!fb.isRevoked) {
                    sum += int256(fb.value);
                    nonRevokedCount++;
                }
            }
        }

        if (nonRevokedCount >= 5) {
            int256 average = (sum * 1e18) / int256(nonRevokedCount);
            stakingManager.checkAndSlash(agentId, average, nonRevokedCount);
        }
    }
}
