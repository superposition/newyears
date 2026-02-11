// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StakingManager
 * @notice Manages native PLASMA staking for agent registration with reputation-based slashing
 * @dev Critical security: Only IdentityRegistry can stake/unstake, only ReputationRegistry can slash
 */
contract StakingManager is ReentrancyGuard, Ownable {
    /// @notice Required stake amount (0.1 PLASMA)
    uint256 public constant STAKE_AMOUNT = 0.1 ether;

    /// @notice Slash percentage (50%)
    uint256 public constant SLASH_PERCENTAGE = 50;

    /// @notice Identity registry contract (authorized to stake/unstake)
    address public identityRegistry;

    /// @notice Reputation registry contract (authorized to check and slash)
    address public reputationRegistry;

    /// @notice Mapping of agentId to staked amount
    mapping(uint256 => uint256) public agentStakes;

    /// @notice Mapping of agentId to whether it has been slashed
    mapping(uint256 => bool) public agentSlashed;

    /// @notice Emitted when stake is locked for an agent
    event StakeLocked(uint256 indexed agentId, address indexed staker, uint256 amount);

    /// @notice Emitted when stake is refunded
    event StakeRefunded(uint256 indexed agentId, address indexed recipient, uint256 amount);

    /// @notice Emitted when stake is slashed
    event StakeSlashed(uint256 indexed agentId, uint256 slashedAmount, uint256 remainingAmount);

    /// @notice Emitted when identity registry is set
    event IdentityRegistrySet(address indexed identityRegistry);

    /// @notice Emitted when reputation registry is set
    event ReputationRegistrySet(address indexed reputationRegistry);

    error Unauthorized();
    error AlreadyStaked();
    error NotStaked();
    error AlreadySlashed();
    error InsufficientStake();
    error TransferFailed();
    error InvalidAddress();
    error InvalidAmount();

    modifier onlyIdentityRegistry() {
        if (msg.sender != identityRegistry) revert Unauthorized();
        _;
    }

    modifier onlyReputationRegistry() {
        if (msg.sender != reputationRegistry) revert Unauthorized();
        _;
    }

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Set the identity registry address (only owner)
     * @param _identityRegistry Address of the identity registry
     */
    function setIdentityRegistry(address _identityRegistry) external onlyOwner {
        if (_identityRegistry == address(0)) revert InvalidAddress();
        identityRegistry = _identityRegistry;
        emit IdentityRegistrySet(_identityRegistry);
    }

    /**
     * @notice Set the reputation registry address (only owner)
     * @param _reputationRegistry Address of the reputation registry
     */
    function setReputationRegistry(address _reputationRegistry) external onlyOwner {
        if (_reputationRegistry == address(0)) revert InvalidAddress();
        reputationRegistry = _reputationRegistry;
        emit ReputationRegistrySet(_reputationRegistry);
    }

    /**
     * @notice Lock stake for agent registration (called by IdentityRegistry)
     * @param agentId Agent ID to stake for
     */
    function stake(uint256 agentId) external payable onlyIdentityRegistry nonReentrant {
        if (agentStakes[agentId] > 0) revert AlreadyStaked();
        if (msg.value != STAKE_AMOUNT) revert InvalidAmount();

        agentStakes[agentId] = STAKE_AMOUNT;
        emit StakeLocked(agentId, tx.origin, STAKE_AMOUNT);
    }

    /**
     * @notice Refund stake on agent deregistration (called by IdentityRegistry)
     * @param recipient Address to receive the refund
     * @param agentId Agent ID to unstake
     */
    function unstake(address recipient, uint256 agentId) external onlyIdentityRegistry nonReentrant {
        uint256 stakedAmount = agentStakes[agentId];
        if (stakedAmount == 0) revert NotStaked();

        // Clear the stake
        delete agentStakes[agentId];
        delete agentSlashed[agentId];

        // Refund remaining stake to recipient
        (bool success,) = recipient.call{value: stakedAmount}("");
        if (!success) revert TransferFailed();
        emit StakeRefunded(agentId, recipient, stakedAmount);
    }

    /**
     * @notice Check and slash stake if reputation is below threshold (called by ReputationRegistry)
     * @param agentId Agent ID to check
     * @param averageReputation Average reputation value (scaled by 1e18)
     * @param feedbackCount Number of feedback entries
     */
    function checkAndSlash(uint256 agentId, int256 averageReputation, uint256 feedbackCount)
        external
        onlyReputationRegistry
        nonReentrant
    {
        uint256 stakedAmount = agentStakes[agentId];
        if (stakedAmount == 0) return; // No stake, nothing to slash

        // Only slash if:
        // 1. Agent has at least 5 feedback entries (prevent early gaming)
        // 2. Average reputation is below -50 (scaled by 1e18, so -50e18)
        // 3. Agent hasn't been slashed already
        if (feedbackCount >= 5 && averageReputation < -50e18 && !agentSlashed[agentId]) {
            // Slash 50% of the stake
            uint256 slashAmount = (stakedAmount * SLASH_PERCENTAGE) / 100;
            uint256 remainingAmount = stakedAmount - slashAmount;

            // Update state
            agentStakes[agentId] = remainingAmount;
            agentSlashed[agentId] = true;

            // Transfer slashed amount to owner (treasury)
            (bool success,) = owner().call{value: slashAmount}("");
            if (!success) revert TransferFailed();

            emit StakeSlashed(agentId, slashAmount, remainingAmount);
        }
    }

    /**
     * @notice Get stake info for an agent
     * @param agentId Agent ID to query
     * @return stakedAmount Current staked amount
     * @return isSlashed Whether the agent has been slashed
     */
    function getStakeInfo(uint256 agentId) external view returns (uint256 stakedAmount, bool isSlashed) {
        return (agentStakes[agentId], agentSlashed[agentId]);
    }

    /**
     * @notice Get total PLASMA balance locked in the contract
     * @return Total balance
     */
    function getTotalStaked() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Accept native PLASMA transfers
    receive() external payable {}
}
