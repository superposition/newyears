# ERC-8004 Trustless Agents Implementation on ROAX

A spec-compliant implementation of [ERC-8004 (Trustless Agents)](https://eips.ethereum.org/EIPS/eip-8004) on the ROAX blockchain with native PLASMA staking extensions. ERC-8004 provides on-chain identity, reputation, and validation registries for AI agents to interact trustlessly across organizational boundaries.

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

### 1. Agent Identity (ERC-721) — Spec Compliant

- Each agent is represented as an ERC-721 NFT with ERC721Enumerable
- **3 registration overloads**: `register()`, `register(uri)`, `register(uri, metadata)` — all payable for PLASMA staking
- Metadata storage with `metadataKey`/`metadataValue` fields (per spec)
- **Agent wallet** stored as metadata under reserved `"agentWallet"` key (auto-set to `msg.sender` on registration)
- Agent wallet verification via EIP-712 signatures (typehash includes `owner`, 5-minute deadline cap)
- `unsetAgentWallet()` to clear the agent wallet
- `isAuthorizedOrOwner()` — owner, approved operator, or `getApproved` can manage agents
- Automatic wallet clearing on NFT transfer with `MetadataSet` event
- Spec events: `Registered`, `MetadataSet`, `URIUpdated`

### 2. Native PLASMA Staking (Custom Extension)

- **Registration**: Send 0.1 PLASMA with any `register()` overload (no separate approval needed)
- **Slashing**: Automatic 50% slash if average reputation < -50 (with >= 5 reviews)
- **Refund**: Remaining stake returned on agent deregistration via `deregister()`
- **Security**: ReentrancyGuard protection on all operations

### 3. Reputation System — Spec Compliant

- **8-param `giveFeedback`**: agentId, value, valueDecimals, tag1, tag2, endpoint, feedbackURI, feedbackHash
- **1-based feedbackIndex** per (agentId, clientAddress) — each client has independent indexing
- **Value validation**: `valueDecimals` 0-18, value in `[-1e38, 1e38]`
- **Tag-Based Filtering**: Two-level tagging for contextual reputation
- **Revocation**: Only the original client can revoke their own feedback (by feedbackIndex)
- **`appendResponse`**: Anyone can respond to feedback (tracked per unique responder)
- **WAD normalization in `getSummary`**: Normalizes all values to 18 decimals, averages, then scales back to mode decimals
- **`readAllFeedback`**: Returns 7 parallel arrays with client/tag filtering
- **Client enumeration**: `getClients()`, `getLastIndex()`, `getResponseCount()`
- **Self-Feedback Prevention**: Uses `isAuthorizedOrOwner` — owner, operators, and approved addresses all blocked
- **Automatic Slashing**: Triggers PLASMA stake slashing on bad reputation (custom extension)
- Spec events: `NewFeedback`, `FeedbackRevoked`, `ResponseAppended`

### 4. Validation Registry — Spec Compliant

- **Caller-provided `requestHash`**: The caller computes and provides the hash (not derived on-chain)
- **Owner-only requests**: Only owner/operator of the agentId can request validation (via `isAuthorizedOrOwner`)
- **Response range 0-100**: 0 is a valid score (not reserved for pending); `hasResponse` flag differentiates
- **Tag in response only**: Tag is set during `validationResponse`, not during request
- **Progressive updates**: Validators can update their response multiple times
- **`getAgentValidations(agentId)`** and **`getValidatorRequests(validatorAddress)`** for enumeration
- **`getSummary`** returns `(count, averageResponse)` — only counts responded validations
- Spec events: `ValidationRequest`, `ValidationResponse`

## Contract Addresses (ROAX Devnet)

Deployed on ROAX network (chainID 135):

```
StakingManager:         0x9BebeA6ebde07C0Ce5c10f9f8Af0Cf323bB45a20
AgentIdentityRegistry:  0xc6cdA43A7D8F3bBf6B298DC25D3029BfFf5b2f7F
ReputationRegistry:     0xa489899C37c3E7E61bE89367Ad8fb0795cC5a32b
ValidationRegistry:     0xFc3529a65720f865b344abf2dDdC94878A59648E
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
- **Give Feedback**: Rate agents (-100 to +100) with tags and endpoint
- **Revoke Feedback**: Revoke your own previously submitted feedback
- **Append Response**: Respond to any feedback entry
- **Deregister Agent**: Owner-only action to burn the agent NFT and reclaim stake
- **Leaderboard**: View agents ranked by reputation (WAD-normalized averages)

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
// Option 1: Bare registration (no URI, no metadata)
uint256 agentId = identityRegistry.register{value: 0.1 ether}();

// Option 2: URI-only registration
uint256 agentId = identityRegistry.register{value: 0.1 ether}("ipfs://agent-metadata-uri");

// Option 3: Full registration with metadata
IERC8004Identity.MetadataEntry[] memory metadata = new IERC8004Identity.MetadataEntry[](1);
metadata[0] = IERC8004Identity.MetadataEntry({
    metadataKey: "name",
    metadataValue: abi.encode("My AI Agent")
});
uint256 agentId = identityRegistry.register{value: 0.1 ether}(
    "ipfs://agent-metadata-uri",
    metadata
);

// Agent wallet is automatically set to msg.sender
address wallet = identityRegistry.getAgentWallet(agentId); // == msg.sender
```

### Submitting Feedback

```solidity
// Give feedback (8 params per spec)
uint64 feedbackIndex = reputationRegistry.giveFeedback(
    agentId,
    80,              // value (int128, range [-1e38, 1e38])
    0,               // valueDecimals (0-18)
    "quality",       // tag1
    "excellent",     // tag2
    "/api/v1/chat",  // endpoint (emit-only)
    "",              // feedbackURI (emit-only)
    bytes32(0)       // feedbackHash (emit-only)
);

// feedbackIndex is 1-based, per (agentId, msg.sender)
// Revoke feedback (only original submitter can revoke their own)
reputationRegistry.revokeFeedback(agentId, feedbackIndex);

// Anyone can respond to feedback
reputationRegistry.appendResponse(agentId, clientAddress, feedbackIndex, "ipfs://response", bytes32(0));
```

### Requesting Validation

```solidity
// Caller provides the requestHash
bytes32 requestHash = keccak256("my-unique-request-id");

// Only owner/operator of agentId can request validation
validationRegistry.validationRequest(
    validatorAddress,
    agentId,
    "ipfs://validation-criteria",
    requestHash
);

// Validator responds (only assigned validator, tag is set here)
validationRegistry.validationResponse(
    requestHash,
    85,                         // score (0-100, 0 is valid)
    "ipfs://validation-report",
    keccak256(abi.encode("report")),
    "security"                  // tag
);
```

### Querying Reputation

```solidity
// Get reputation summary (all feedback) — returns (count, summaryValue, summaryValueDecimals)
address[] memory clients = new address[](0);
(uint64 count, int128 summaryValue, uint8 summaryValueDecimals) =
    reputationRegistry.getSummary(agentId, clients, "", "");

// Filter by specific clients
address[] memory specificClients = new address[](1);
specificClients[0] = clientAddress;
(count, summaryValue, summaryValueDecimals) =
    reputationRegistry.getSummary(agentId, specificClients, "", "");

// Filter by tags
(count, summaryValue, summaryValueDecimals) =
    reputationRegistry.getSummary(agentId, clients, "quality", "");

// Read individual feedback
(int128 value, uint8 decimals, string memory tag1, string memory tag2, bool isRevoked) =
    reputationRegistry.readFeedback(agentId, clientAddress, feedbackIndex);

// Enumerate clients who gave feedback
address[] memory feedbackClients = reputationRegistry.getClients(agentId);
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
- **Agent Management**: Owner, approved operators (`setApprovalForAll`), or `getApproved` addresses can manage agents (URI, metadata, wallet)
- **Reserved metadata key**: `"agentWallet"` cannot be set via `setMetadata()` or `register()` metadata — use `setAgentWallet()` instead
- **Feedback**: Owner, operators, and approved addresses are all blocked from self-feedback (via `isAuthorizedOrOwner`)
- **Validation requests**: Only owner/operator of the agentId can request validations
- **Validation responses**: Only the assigned validator can submit responses

### Signature Verification (EIP-712)

- Domain name: `"ERC8004IdentityRegistry"` (per spec)
- Typehash: `AgentWalletSet(uint256 agentId,address newWallet,address owner,uint256 deadline)` — includes `owner`
- Domain separator includes chainId (prevents cross-chain replay attacks)
- **5-minute deadline cap**: `deadline` must be `<= block.timestamp + 5 minutes`
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
