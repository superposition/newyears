// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureVerifier
 * @notice Library for EIP-712 signature verification with support for EOA and smart contract wallets (ERC-1271)
 * @dev Used to verify agent wallet signatures
 */
library SignatureVerifier {
    using ECDSA for bytes32;

    /// @notice EIP-712 domain typehash
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice EIP-712 SetAgentWallet typehash
    bytes32 public constant SET_AGENT_WALLET_TYPEHASH =
        keccak256("SetAgentWallet(uint256 agentId,address agentWallet,uint256 deadline)");

    /// @notice ERC-1271 magic value for valid signature
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    /**
     * @notice Compute EIP-712 domain separator
     * @param name The contract name
     * @param version The contract version
     * @param chainId The chain ID
     * @param verifyingContract The contract address
     * @return The domain separator hash
     */
    function computeDomainSeparator(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );
    }

    /**
     * @notice Compute EIP-712 struct hash for SetAgentWallet
     * @param agentId The agent ID
     * @param agentWallet The agent wallet address
     * @param deadline The signature deadline
     * @return The struct hash
     */
    function hashSetAgentWallet(uint256 agentId, address agentWallet, uint256 deadline)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(SET_AGENT_WALLET_TYPEHASH, agentId, agentWallet, deadline));
    }

    /**
     * @notice Compute EIP-712 typed data hash
     * @param domainSeparator The domain separator
     * @param structHash The struct hash
     * @return The typed data hash
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    /**
     * @notice Verify EIP-712 signature for SetAgentWallet
     * @param domainSeparator The domain separator
     * @param agentId The agent ID
     * @param agentWallet The expected signer (agent wallet)
     * @param deadline The signature deadline
     * @param signature The signature bytes
     * @return True if signature is valid and not expired
     */
    function verifySetAgentWallet(
        bytes32 domainSeparator,
        uint256 agentId,
        address agentWallet,
        uint256 deadline,
        bytes memory signature
    ) internal view returns (bool) {
        // Check deadline
        if (block.timestamp > deadline) {
            return false;
        }

        // Compute typed data hash
        bytes32 structHash = hashSetAgentWallet(agentId, agentWallet, deadline);
        bytes32 digest = toTypedDataHash(domainSeparator, structHash);

        // Check if agentWallet is a contract (ERC-1271) or EOA (ECDSA)
        if (agentWallet.code.length > 0) {
            // Smart contract wallet - use ERC-1271
            try IERC1271(agentWallet).isValidSignature(digest, signature) returns (bytes4 magicValue) {
                return magicValue == ERC1271_MAGIC_VALUE;
            } catch {
                return false;
            }
        } else {
            // EOA - use ECDSA
            address recoveredSigner = digest.recover(signature);
            return recoveredSigner == agentWallet;
        }
    }
}
