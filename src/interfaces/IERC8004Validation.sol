// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC8004Validation
 * @notice Interface for ERC-8004 Agent Validation Registry
 * @dev Request/response model for validator attestations
 */
interface IERC8004Validation {
    /**
     * @notice Validation record structure
     * @param requestor Address that requested the validation
     * @param validatorAddress Address of the validator
     * @param agentId Agent ID being validated
     * @param uri URI with validation criteria or report
     * @param uriHash Hash of the validation criteria
     * @param tag Tag for categorization
     * @param response Validation score (0-100, 0 means pending)
     * @param responseHash Hash of the validation response
     * @param lastUpdate Timestamp of last update
     */
    struct ValidationRecord {
        address requestor;
        address validatorAddress;
        uint256 agentId;
        string uri;
        bytes32 uriHash;
        string tag;
        uint8 response;
        bytes32 responseHash;
        uint256 lastUpdate;
    }

    /**
     * @notice Validation summary
     * @param agentId The agent ID
     * @param totalValidations Total number of validations
     * @param passedCount Number of passed validations (response >= 50)
     * @param failedCount Number of failed validations (response < 50 and > 0)
     * @param pendingCount Number of pending validations (response == 0)
     * @param averageScore Average validation score (excluding pending)
     */
    struct ValidationSummary {
        uint256 agentId;
        uint256 totalValidations;
        uint256 passedCount;
        uint256 failedCount;
        uint256 pendingCount;
        uint256 averageScore;
    }

    /**
     * @notice Emitted when a validation is requested
     * @param requestHash Unique hash identifying this validation request
     * @param requestor Address requesting the validation
     * @param validator Address of the validator
     * @param agentId Agent ID to validate
     * @param tag Validation category tag
     */
    event ValidationRequested(
        bytes32 indexed requestHash,
        address indexed requestor,
        address indexed validator,
        uint256 agentId,
        string tag
    );

    /**
     * @notice Emitted when a validator submits a response
     * @param requestHash Unique hash identifying the validation request
     * @param validator Address of the validator
     * @param agentId Agent ID
     * @param response Validation score (0-100)
     */
    event ValidationResponse(
        bytes32 indexed requestHash, address indexed validator, uint256 indexed agentId, uint8 response
    );

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
    ) external returns (bytes32 requestHash);

    /**
     * @notice Validator submits a validation response
     * @param requestHash The validation request hash
     * @param response Validation score (0-100, where 0 is invalid for response)
     * @param responseUri URI with detailed validation report
     * @param responseHash Hash of the validation response
     */
    function validationResponse(
        bytes32 requestHash,
        uint8 response,
        string calldata responseUri,
        bytes32 responseHash
    ) external;

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
        returns (ValidationSummary memory summary);

    /**
     * @notice Get specific validation record
     * @param requestHash The validation request hash
     * @return The validation record
     */
    function getValidation(bytes32 requestHash) external view returns (ValidationRecord memory);

    /**
     * @notice Get all validations for an agent
     * @param agentId The agent ID
     * @return Array of validation records
     */
    function getAllValidations(uint256 agentId) external view returns (ValidationRecord[] memory);

    /**
     * @notice Get total number of validations for an agent
     * @param agentId The agent ID
     * @return Total validation count
     */
    function getValidationCount(uint256 agentId) external view returns (uint256);

    /**
     * @notice Check if a validation exists
     * @param requestHash The validation request hash
     * @return True if the validation exists
     */
    function validationExists(bytes32 requestHash) external view returns (bool);
}
