// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC8004Validation
 * @notice Interface for ERC-8004 Agent Validation Registry
 * @dev Request/response model for validator attestations
 */
interface IERC8004Validation {
    struct ValidationStatus {
        address validatorAddress;
        uint256 agentId;
        uint8 response;
        bytes32 responseHash;
        string tag;
        uint256 lastUpdate;
        bool hasResponse;
    }

    // ── Spec Events ──

    event ValidationRequest(
        address indexed validatorAddress,
        uint256 indexed agentId,
        string requestURI,
        bytes32 indexed requestHash
    );

    event ValidationResponse(
        address indexed validatorAddress,
        uint256 indexed agentId,
        bytes32 indexed requestHash,
        uint8 response,
        string responseURI,
        bytes32 responseHash,
        string tag
    );

    // ── Functions ──

    function validationRequest(
        address validatorAddress,
        uint256 agentId,
        string calldata requestURI,
        bytes32 requestHash
    ) external;

    function validationResponse(
        bytes32 requestHash,
        uint8 response,
        string calldata responseURI,
        bytes32 responseHash,
        string calldata tag
    ) external;

    function getValidationStatus(bytes32 requestHash)
        external
        view
        returns (address, uint256, uint8, bytes32, string memory, uint256);

    function getSummary(uint256 agentId, address[] calldata validatorAddresses, string calldata tag)
        external
        view
        returns (uint64 count, uint8 averageResponse);

    function getAgentValidations(uint256 agentId) external view returns (bytes32[] memory);

    function getValidatorRequests(address validatorAddress) external view returns (bytes32[] memory);
}
