# ERC-8004 Trustless Agents Implementation on ROAX

A complete implementation of [ERC-8004 (Trustless Agents)](https://eips.ethereum.org/EIPS/eip-8004) on the ROAX blockchain with native PLASMA staking requirements. ERC-8004 provides on-chain identity, reputation, and validation registries for AI agents to interact trustlessly across organizational boundaries.

## Overview

ERC-8004 enables AI agents to:
- **Establish persistent on-chain identities** as ERC-721 NFTs
- **Build verifiable reputations** through structured feedback with revocation and aggregation
- **Undergo independent validation** by third-party validators with attestation tracking

**Custom Implementation**: This implementation requires a 0.1 PLASMA (native token) stake per agent registration to prevent spam and ensure economic accountability. Stakes are automatically slashed by 50% if an agent's average reputation falls below -50 (with at least 5 reviews).

## Architecture

### Project Structure

```
├── src/                              # Smart contracts
│   ├── interfaces/
│   │   ├── IERC8004Identity.sol      # Identity registry interface
│   │   ├── IERC8004Reputation.sol    # Reputation registry interface
│   │   └── IERC8004Validation.sol    # Validation registry interface
│   ├── libraries/
│   │   └── SignatureVerifier.sol     # EIP-712 signature verification
│   ├── AgentIdentityRegistry.sol     # ERC-721 agent identities
│   ├── StakingManager.sol            # Native PLASMA staking with slashing
│   ├── ReputationRegistry.sol        # Feedback and reputation system
│   └── ValidationRegistry.sol        # Validator attestations
├── test/                             # Tests
│   ├── unit/                         # Unit tests per contract
│   ├── integration/                  # End-to-end flow tests
│   └── TestHelper.sol                # Base test contract
├── script/                           # Deployment scripts
├── frontend/                         # Next.js explorer & interaction UI
│   ├── app/                          # Pages (agents, create, feedback, leaderboard)
│   ├── components/                   # UI components & providers
│   └── lib/                          # Contract ABIs, addresses, hooks
├── foundry.toml                      # Foundry configuration
└── README.md
```

### Contract Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                     User (Agent Owner)                       │
└───────────┬─────────────────────────────────────────────────┘
            │
            │ register{value: 0.1 PLASMA}()
            ▼
┌─────────────────────────┐       Mints NFT
│  AgentIdentityRegistry  │◄──────────────┐
│      (ERC-721)          │                │
└────────┬────────────────┘                │
         │                                 │
         │ Forwards 0.1 PLASMA             │
         ▼                                 │
┌─────────────────────────┐                │
│    StakingManager       │                │
│ (Holds native stakes)   │                │
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

### 2. Native PLASMA Staking

- **Registration**: Send 0.1 PLASMA with the `register()` call (no separate approval needed)
- **Slashing**: Automatic 50% slash if average reputation < -50 (with >= 5 reviews)
- **Refund**: Remaining stake returned on agent deregistration
- **Security**: ReentrancyGuard protection on all operations

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
- **Pass/Fail Tracking**: Scores >= 50 = passed, < 50 = failed
- **Tag Categorization**: Validation types (security, performance, etc.)
- **Summary Aggregation**: Filter by validator and tag

## Contract Addresses (ROAX Devnet)

Deployed on ROAX network (chainID 135):

```
StakingManager:         0xd76F626334BE6970ac0F3C5A25bBe4A8eF07F6cc
AgentIdentityRegistry:  0x646306682cD4AB18007c6b7B4AA54Aa0731d49A8
ReputationRegistry:     0x8d66B496FdaA46c3885b6A485E36e4291fCc969F
ValidationRegistry:     0xa95062757f6A17682Fe70B00Ed7b485D4767E0cd
```

## Frontend

The frontend is a Next.js app that lets users browse agents, register new agents, give feedback, and view reputation/validation data.

### Setup

```bash
cd frontend
pnpm install   # or npm install
pnpm dev       # starts on http://localhost:3000
```

### Features

- **Browse Agents**: View all registered agents with reputation summaries
- **Register Agent**: Connect wallet, fill in metadata, stake 0.1 PLASMA to mint an agent NFT
- **Give Feedback**: Rate agents (-100 to +100) with tags and comments
- **Revoke Feedback**: Revoke your own previously submitted feedback
- **Deregister Agent**: Owner-only action to burn the agent NFT and reclaim stake
- **Leaderboard**: View agents ranked by reputation

### Tech Stack

- Next.js 15 + React 19
- wagmi v2 + viem for contract interactions
- RainbowKit for wallet connection
- Tailwind CSS v4

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
forge coverage
```

### Gas Report

```bash
forge test --gas-report
```

## Usage Guide

### Registering an Agent

```solidity
// Prepare metadata
IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](1);
metadata[0] = IERC8004Identity.MetadataEntry({
    key: "name",
    value: abi.encode("My AI Agent")
});

// Register agent — sends 0.1 PLASMA as native value
uint256 agentId = identityRegistry.register{value: 0.1 ether}(
    "ipfs://agent-metadata-uri",
    metadata
);
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

- All native token transfer operations use `ReentrancyGuard`
- Pull-over-push pattern for stake refunds

### Slashing Protection

- Requires minimum 5 feedback entries before slashing
- One-time slashing per agent (prevents double slashing)
- Reputation threshold: -50 (scaled by 1e18)

### Sybil Resistance

- 0.1 PLASMA stake requirement increases cost of spam
- Self-feedback prevention
- Client address filtering in reputation summaries

## References

- [ERC-8004 Official Specification](https://eips.ethereum.org/EIPS/eip-8004)
- [ROAX Network Documentation](https://roax.net)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT

---

**Built with [Foundry](https://getfoundry.sh/) + [Next.js](https://nextjs.org/) | Deployed on [ROAX Network](https://roax.net)**
