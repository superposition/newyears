// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC8004Validation} from "./interfaces/IERC8004Validation.sol";
import {AgentIdentityRegistry} from "./AgentIdentityRegistry.sol";

/**
 * @title ValidationRegistry
 * @notice ERC-8004 spec-compliant validation registry
 * @dev Caller-provided requestHash, response 0-100 with hasResponse flag, tag in response only
 */
contract ValidationRegistry is IERC8004Validation {
    AgentIdentityRegistry public immutable identityRegistry;

    /// @notice Validation status by requestHash
    mapping(bytes32 => ValidationStatus) private _validations;

    /// @notice Agent validations tracking
    mapping(uint256 => bytes32[]) private _agentValidations;
    mapping(uint256 => mapping(bytes32 => bool)) private _agentValidationExists;

    /// @notice Validator request tracking
    mapping(address => bytes32[]) private _validatorRequests;
    mapping(address => mapping(bytes32 => bool)) private _validatorRequestExists;

    error AgentNotFound();
    error NotAuthorized();
    error ValidationNotFound();
    error ValidationAlreadyExists();
    error InvalidResponse();

    constructor(address _identityRegistry) {
        if (_identityRegistry == address(0)) revert AgentNotFound();
        identityRegistry = AgentIdentityRegistry(_identityRegistry);
    }

    function validationRequest(
        address validatorAddress,
        uint256 agentId,
        string calldata requestURI,
        bytes32 requestHash
    ) external override {
        if (!identityRegistry.exists(agentId)) revert AgentNotFound();

        // Only owner/operator of agentId can request validation
        if (!identityRegistry.isAuthorizedOrOwner(msg.sender, agentId)) revert NotAuthorized();

        // Check for duplicate
        if (_validations[requestHash].lastUpdate != 0) revert ValidationAlreadyExists();

        _validations[requestHash] = ValidationStatus({
            validatorAddress: validatorAddress,
            agentId: agentId,
            response: 0,
            responseHash: bytes32(0),
            tag: "",
            lastUpdate: block.timestamp,
            hasResponse: false
        });

        // Track for agent
        if (!_agentValidationExists[agentId][requestHash]) {
            _agentValidations[agentId].push(requestHash);
            _agentValidationExists[agentId][requestHash] = true;
        }

        // Track for validator
        if (!_validatorRequestExists[validatorAddress][requestHash]) {
            _validatorRequests[validatorAddress].push(requestHash);
            _validatorRequestExists[validatorAddress][requestHash] = true;
        }

        emit ValidationRequest(validatorAddress, agentId, requestURI, requestHash);
    }

    function validationResponse(
        bytes32 requestHash,
        uint8 response,
        string calldata responseURI,
        bytes32 responseHash,
        string calldata tag
    ) external override {
        ValidationStatus storage record = _validations[requestHash];
        if (record.lastUpdate == 0) revert ValidationNotFound();

        // Only assigned validator can respond
        if (msg.sender != record.validatorAddress) revert NotAuthorized();

        // Response range: 0-100 (0 is valid per spec, hasResponse differentiates from pending)
        if (response > 100) revert InvalidResponse();

        record.response = response;
        record.responseHash = responseHash;
        record.tag = tag;
        record.lastUpdate = block.timestamp;
        record.hasResponse = true;

        emit ValidationResponse(msg.sender, record.agentId, requestHash, response, responseURI, responseHash, tag);
    }

    function getValidationStatus(bytes32 requestHash)
        external
        view
        override
        returns (address, uint256, uint8, bytes32, string memory, uint256)
    {
        ValidationStatus storage record = _validations[requestHash];
        if (record.lastUpdate == 0) revert ValidationNotFound();
        return (
            record.validatorAddress,
            record.agentId,
            record.response,
            record.responseHash,
            record.tag,
            record.lastUpdate
        );
    }

    function getSummary(uint256 agentId, address[] calldata validatorAddresses, string calldata tag)
        external
        view
        override
        returns (uint64 count, uint8 averageResponse)
    {
        bytes32[] storage requestHashes = _agentValidations[agentId];

        bool filterByValidator = validatorAddresses.length > 0;
        bool filterByTag = bytes(tag).length > 0;

        uint256 totalCount = 0;
        uint256 scoreSum = 0;

        for (uint256 i = 0; i < requestHashes.length; i++) {
            ValidationStatus storage record = _validations[requestHashes[i]];

            // Only count responded validations
            if (!record.hasResponse) continue;

            // Apply validator filter
            if (filterByValidator) {
                bool matchesValidator = false;
                for (uint256 j = 0; j < validatorAddresses.length; j++) {
                    if (record.validatorAddress == validatorAddresses[j]) {
                        matchesValidator = true;
                        break;
                    }
                }
                if (!matchesValidator) continue;
            }

            // Apply tag filter
            if (filterByTag && keccak256(bytes(record.tag)) != keccak256(bytes(tag))) continue;

            totalCount++;
            scoreSum += record.response;
        }

        count = uint64(totalCount);
        averageResponse = totalCount > 0 ? uint8(scoreSum / totalCount) : 0;
    }

    function getAgentValidations(uint256 agentId) external view override returns (bytes32[] memory) {
        return _agentValidations[agentId];
    }

    function getValidatorRequests(address validatorAddress) external view override returns (bytes32[] memory) {
        return _validatorRequests[validatorAddress];
    }
}
