// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC8004Validation} from "./interfaces/IERC8004Validation.sol";
import {AgentIdentityRegistry} from "./AgentIdentityRegistry.sol";

/**
 * @title ValidationRegistry
 * @notice Manages validation requests and responses for ERC-8004 agents
 * @dev Request/response model with score tracking and aggregation
 */
contract ValidationRegistry is IERC8004Validation {
    /// @notice Identity registry contract
    AgentIdentityRegistry public immutable identityRegistry;

    /// @notice Mapping of requestHash to ValidationRecord
    mapping(bytes32 => ValidationRecord) private _validations;

    /// @notice Mapping of agentId to array of request hashes
    mapping(uint256 => bytes32[]) private _agentValidations;

    error AgentNotFound();
    error ValidationNotFound();
    error ValidationAlreadyExists();
    error Unauthorized();
    error InvalidResponse();

    /**
     * @notice Constructor
     * @param _identityRegistry Address of the identity registry
     */
    constructor(address _identityRegistry) {
        if (_identityRegistry == address(0)) revert AgentNotFound();
        identityRegistry = AgentIdentityRegistry(_identityRegistry);
    }

    /**
     * @notice Request validation for an agent
     * @param validator Address of the validator to request from
     * @param agentId Agent ID to validate
     * @param uri URI with validation criteria or details
     * @param uriHash Hash of the validation criteria
     * @param tag Tag for categorization
     * @return requestHash Unique hash identifying this validation request
     */
    function validationRequest(
        address validator,
        uint256 agentId,
        string calldata uri,
        bytes32 uriHash,
        string calldata tag
    ) external override returns (bytes32 requestHash) {
        // Check agent exists
        if (!identityRegistry.exists(agentId)) revert AgentNotFound();

        // Generate unique request hash
        requestHash = keccak256(abi.encodePacked(msg.sender, validator, agentId, uriHash, block.timestamp));

        // Check for duplicate
        if (_validations[requestHash].lastUpdate != 0) revert ValidationAlreadyExists();

        // Create validation record
        ValidationRecord memory record = ValidationRecord({
            requestor: msg.sender,
            validatorAddress: validator,
            agentId: agentId,
            uri: uri,
            uriHash: uriHash,
            tag: tag,
            response: 0, // 0 means pending
            responseHash: bytes32(0),
            lastUpdate: block.timestamp
        });

        _validations[requestHash] = record;
        _agentValidations[agentId].push(requestHash);

        emit ValidationRequested(requestHash, msg.sender, validator, agentId, tag);
    }

    /**
     * @notice Validator submits a validation response
     * @param requestHash The validation request hash
     * @param response Validation score (1-100, where 0 is invalid)
     * @param responseUri URI with detailed validation report
     * @param responseHash Hash of the validation response
     */
    function validationResponse(
        bytes32 requestHash,
        uint8 response,
        string calldata responseUri,
        bytes32 responseHash
    ) external override {
        ValidationRecord storage record = _validations[requestHash];

        // Check validation exists
        if (record.lastUpdate == 0) revert ValidationNotFound();

        // Only assigned validator can respond
        if (msg.sender != record.validatorAddress) revert Unauthorized();

        // Response must be between 1-100 (0 is reserved for pending)
        if (response == 0 || response > 100) revert InvalidResponse();

        // Update record
        record.response = response;
        record.responseHash = responseHash;
        record.lastUpdate = block.timestamp;

        // Update URI if provided
        if (bytes(responseUri).length > 0) {
            record.uri = responseUri;
        }

        emit ValidationResponse(requestHash, msg.sender, record.agentId, response);
    }

    /**
     * @notice Get validation summary for an agent
     * @param agentId The agent ID
     * @param validators Array of validator addresses to filter by (empty for all)
     * @param tag Tag filter (empty for all)
     * @return summary The aggregated validation summary
     */
    function getSummary(uint256 agentId, address[] calldata validators, string calldata tag)
        external
        view
        override
        returns (ValidationSummary memory summary)
    {
        bytes32[] storage requestHashes = _agentValidations[agentId];

        // Filter flags
        bool filterByValidator = validators.length > 0;
        bool filterByTag = bytes(tag).length > 0;

        // Aggregate validations
        uint256 totalCount = 0;
        uint256 passedCount = 0;
        uint256 failedCount = 0;
        uint256 pendingCount = 0;
        uint256 scoreSum = 0;
        uint256 scoredCount = 0;

        for (uint256 i = 0; i < requestHashes.length; i++) {
            ValidationRecord storage record = _validations[requestHashes[i]];

            // Apply validator filter
            if (filterByValidator) {
                bool matchesValidator = false;
                for (uint256 j = 0; j < validators.length; j++) {
                    if (record.validatorAddress == validators[j]) {
                        matchesValidator = true;
                        break;
                    }
                }
                if (!matchesValidator) continue;
            }

            // Apply tag filter
            if (filterByTag && keccak256(bytes(record.tag)) != keccak256(bytes(tag))) continue;

            totalCount++;

            if (record.response == 0) {
                pendingCount++;
            } else if (record.response >= 50) {
                passedCount++;
                scoreSum += record.response;
                scoredCount++;
            } else {
                failedCount++;
                scoreSum += record.response;
                scoredCount++;
            }
        }

        // Compute average score (excluding pending)
        uint256 averageScore = scoredCount > 0 ? scoreSum / scoredCount : 0;

        summary = ValidationSummary({
            agentId: agentId,
            totalValidations: totalCount,
            passedCount: passedCount,
            failedCount: failedCount,
            pendingCount: pendingCount,
            averageScore: averageScore
        });
    }

    /**
     * @notice Get specific validation record
     * @param requestHash The validation request hash
     * @return The validation record
     */
    function getValidation(bytes32 requestHash) external view override returns (ValidationRecord memory) {
        ValidationRecord storage record = _validations[requestHash];
        if (record.lastUpdate == 0) revert ValidationNotFound();
        return record;
    }

    /**
     * @notice Get all validations for an agent
     * @param agentId The agent ID
     * @return Array of validation records
     */
    function getAllValidations(uint256 agentId) external view override returns (ValidationRecord[] memory) {
        bytes32[] storage requestHashes = _agentValidations[agentId];
        ValidationRecord[] memory records = new ValidationRecord[](requestHashes.length);

        for (uint256 i = 0; i < requestHashes.length; i++) {
            records[i] = _validations[requestHashes[i]];
        }

        return records;
    }

    /**
     * @notice Get total number of validations for an agent
     * @param agentId The agent ID
     * @return Total validation count
     */
    function getValidationCount(uint256 agentId) external view override returns (uint256) {
        return _agentValidations[agentId].length;
    }

    /**
     * @notice Check if a validation exists
     * @param requestHash The validation request hash
     * @return True if the validation exists
     */
    function validationExists(bytes32 requestHash) external view override returns (bool) {
        return _validations[requestHash].lastUpdate != 0;
    }
}
