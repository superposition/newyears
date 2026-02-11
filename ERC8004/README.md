# ERC-8004 Trustless Agents Implementation on ROAX

A complete implementation of [ERC-8004 (Trustless Agents)](https://eips.ethereum.org/EIPS/eip-8004) on the ROAX blockchain with PLASMA token staking requirements. ERC-8004 provides on-chain identity, reputation, and validation registries for AI agents to interact trustlessly across organizational boundaries.

## Overview

ERC-8004 enables AI agents to:
- **Establish persistent on-chain identities** as ERC-721 NFTs
- **Build verifiable reputations** through structured feedback with revocation and aggregation
- **Undergo independent validation** by third-party validators with attestation tracking

**Custom Implementation**: This implementation requires a 0.1 PLASMA token stake per agent registration to prevent spam and ensure economic accountability. Stakes are automatically slashed by 50% if an agent's average reputation falls below -50 (with at least 5 reviews).

## Architecture

### Smart Contracts

```
src/
├── interfaces/
│   ├── IERC8004Identity.sol         # Identity registry interface
│   ├── IERC8004Reputation.sol       # Reputation registry interface
│   └── IERC8004Validation.sol       # Validation registry interface
├── libraries/
│   └── SignatureVerifier.sol        # EIP-712 signature verification
├── AgentIdentityRegistry.sol        # ERC-721 agent identities
├── StakingManager.sol               # PLASMA token staking with slashing
├── ReputationRegistry.sol           # Feedback and reputation system
├── ValidationRegistry.sol           # Validator attestations
└── mocks/
    └── MockPLASMAToken.sol          # Mock PLASMA token for testing
```

### Contract Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                     User (Agent Owner)                       │
└───────────┬─────────────────────────────────────────────────┘
            │
            │ 1. Approve 0.1 PLASMA
            │ 2. register()
            ▼
┌─────────────────────────┐       Mints NFT
│  AgentIdentityRegistry  │◄──────────────┐
│      (ERC-721)          │                │
└────────┬────────────────┘                │
         │                                 │
         │ Stakes 0.1 PLASMA               │
         ▼                                 │
┌─────────────────────────┐                │
│    StakingManager       │                │
│  (Holds PLASMA stakes)  │                │
└────────┬────────────────┘                │
         │                                 │
         │ Triggers slashing               │
         ▲                                 │
         │                                 │
┌────────┴────────────────┐                │
│  ReputationRegistry     │                │
│  (Feedback & Ratings)   │────────────────┘
└─────────────────────────┘   Checks agent exists

┌─────────────────────────┐
│  ValidationRegistry     │
│ (Validator Attestations)│
└─────────────────────────┘
```

## Key Features

### 1. Agent Identity (ERC-721)

- Each agent is represented as an ERC-721 NFT
- Supports metadata storage (key-value pairs)
- Agent wallet verification via EIP-712 signatures
- Automatic wallet clearing on NFT transfer
- Enumerable for efficient agent discovery

### 2. PLASMA Staking

- **Registration**: Requires 0.1 PLASMA token approval and stake
- **Slashing**: Automatic 50% slash if average reputation < -50 (with ≥5 reviews)
- **Refund**: Remaining stake returned on agent deregistration
- **Security**: ReentrancyGuard protection on all token operations

### 3. Reputation System

- **Structured Feedback**: int128 value with configurable decimals (supports percentages, scores, monetary amounts)
- **Tag-Based Filtering**: Two-level tagging for contextual reputation (e.g., "speed"/"fast", "quality"/"excellent")
- **Revocation**: Feedback submitters can revoke their feedback
- **Response Mechanism**: Agent owners can respond to feedback
- **Aggregation**: Average, min, max reputation with client/tag filtering
- **Self-Feedback Prevention**: Agent owners cannot rate their own agents
- **Automatic Slashing**: Triggers stake slashing on bad reputation

### 4. Validation Registry

- **Request/Response Model**: Requestors initiate validation, validators respond
- **Score Range**: 1-100, where 0 is reserved for pending validations
- **Pass/Fail Tracking**: Scores ≥50 = passed, <50 = failed
- **Tag Categorization**: Validation types (security, performance, etc.)
- **Summary Aggregation**: Filter by validator and tag

## Deployment

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

### Environment Setup

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your values:
# - PRIVATE_KEY: Your deployer wallet private key
# - PLASMA_TOKEN_ADDRESS: Existing PLASMA token (optional, will deploy mock if not set)
# - ROAX_RPC_URL: https://devrpc.roax.net
```

### Deploy to ROAX Network

```bash
# Load environment variables
source .env

# Deploy to ROAX (chainID 135)
forge script script/DeployToRoax.s.sol \
  --rpc-url $ROAX_RPC_URL \
  --broadcast \
  --legacy

# Deployment addresses will be saved to deployments-135.json
```

### Deploy Locally (for testing)

```bash
# Start local Anvil node
anvil

# Deploy to local node
forge script script/Deploy.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

## Testing

### Run All Tests

```bash
# Run all tests (unit + integration)
forge test

# Run with verbosity
forge test -vv

# Run specific test file
forge test --match-path test/unit/AgentIdentityRegistry.t.sol
```

### Test Coverage

```bash
# Generate coverage report
forge coverage

# Generate detailed coverage report
forge coverage --report lcov
```

**Test Statistics**:
- **Unit Tests**: 65 tests covering all contracts
- **Integration Tests**: 6 end-to-end flow tests
- **Total**: 71 tests, 100% passing

### Gas Report

```bash
forge test --gas-report
```

## Usage Guide

### Registering an Agent

```solidity
// 1. Approve PLASMA tokens
IERC20(plasmaToken).approve(address(stakingManager), 0.1 ether);

// 2. Prepare metadata
IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](1);
metadata[0] = IERC8004Identity.MetadataEntry({
    key: "name",
    value: abi.encode("My AI Agent")
});

// 3. Register agent
uint256 agentId = identityRegistry.register("ipfs://agent-metadata-uri", metadata);
```

### Submitting Feedback

```solidity
// Give feedback (value: -100 to 100, decimals: 0 for integers)
uint64 feedbackIndex = reputationRegistry.giveFeedback(
    agentId,
    80,          // value
    0,           // decimals
    "quality",   // tag1
    "excellent", // tag2
    "Great work!" // comment
);

// Revoke feedback (only original submitter)
reputationRegistry.revokeFeedback(agentId, feedbackIndex);
```

### Requesting Validation

```solidity
// Request validation from validator
bytes32 requestHash = validationRegistry.validationRequest(
    validatorAddress,
    agentId,
    "ipfs://validation-criteria",
    keccak256(abi.encode("criteria")),
    "security"
);

// Validator responds (only assigned validator)
validationRegistry.validationResponse(
    requestHash,
    85,                        // score (1-100)
    "ipfs://validation-report",
    keccak256(abi.encode("report"))
);
```

### Querying Reputation

```solidity
// Get reputation summary (all feedback)
address[] memory clients = new address[](0);
IERC8004Reputation.ReputationSummary memory summary =
    reputationRegistry.getSummary(agentId, clients, "", "");

// Filter by specific clients
address[] memory specificClients = new address[](1);
specificClients[0] = clientAddress;
summary = reputationRegistry.getSummary(agentId, specificClients, "", "");

// Filter by tags
summary = reputationRegistry.getSummary(agentId, clients, "quality", "");
```

### Deregistering an Agent

```solidity
// Burns NFT and refunds remaining stake
identityRegistry.deregister(agentId);
// If slashed: refunds 0.05 PLASMA
// If not slashed: refunds 0.1 PLASMA
```

## Security Considerations

### Access Control

- **StakingManager**: Only IdentityRegistry can stake/unstake, only ReputationRegistry can slash
- **Agent Management**: Only agent owner can update URI, metadata, and set agent wallet
- **Feedback**: Agent owners cannot submit feedback on their own agents
- **Validation**: Only assigned validators can submit responses

### Signature Verification (EIP-712)

- Domain separator includes chainId (prevents cross-chain replay attacks)
- Deadline parameter prevents stale signatures
- Supports both EOA (ECDSA) and smart contract wallets (ERC-1271)

### Reentrancy Protection

- All token transfer operations use `ReentrancyGuard`
- Pull-over-push pattern for stake refunds

### Slashing Protection

- Requires minimum 5 feedback entries before slashing
- One-time slashing per agent (prevents double slashing)
- Reputation threshold: -50 (scaled by 1e18)

### Sybil Resistance

- 0.1 PLASMA stake requirement increases cost of spam
- Self-feedback prevention
- Client address filtering in reputation summaries

## Contract Addresses

After deployment to ROAX network (chainID 135):

```
PLASMA Token:           <deployed_address>
StakingManager:         <deployed_address>
AgentIdentityRegistry:  <deployed_address>
ReputationRegistry:     <deployed_address>
ValidationRegistry:     <deployed_address>
```

Addresses are saved in `deployments-135.json` after deployment.

## Development

### Project Structure

```
ERC8004/
├── src/                      # Smart contracts
│   ├── interfaces/           # ERC-8004 interfaces
│   ├── libraries/            # Helper libraries
│   └── mocks/                # Mock contracts for testing
├── test/                     # Tests
│   ├── unit/                 # Unit tests per contract
│   ├── integration/          # End-to-end flow tests
│   └── TestHelper.sol        # Base test contract
├── script/                   # Deployment scripts
├── foundry.toml              # Foundry configuration
└── README.md                 # This file
```

### Build

```bash
forge build
```

### Format

```bash
forge fmt
```

### Clean

```bash
forge clean
```

## References

- [ERC-8004 Official Specification](https://eips.ethereum.org/EIPS/eip-8004)
- [ERC-8004 Reference Implementation](https://github.com/erc-8004/erc-8004-contracts)
- [Ethereum Magicians Discussion](https://ethereum-magicians.org/t/erc-8004-trustless-agents/25098)
- [ROAX Network Documentation](https://roax.net)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT

## Contributing

This is a reference implementation for educational and testing purposes. For production use, consider:

1. **Security Audit**: Conduct thorough security audit by reputable firm
2. **Gas Optimization**: Further optimize gas costs for high-volume scenarios
3. **Governance**: Implement governance mechanisms for parameter updates
4. **Emergency Controls**: Add pause functionality and upgrade paths
5. **Economic Analysis**: Model staking economics and slashing impacts

## Support

For issues or questions:
- GitHub Issues: [Submit an issue](https://github.com/anthropics/claude-code/issues)
- ERC-8004 Discussion: [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8004-trustless-agents/25098)

---

**Built with [Foundry](https://getfoundry.sh/) | Deployed on [ROAX Network](https://roax.net)**
