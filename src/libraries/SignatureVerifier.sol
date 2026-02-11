// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureVerifier
 * @notice Library for EIP-712 signature verification with support for EOA and smart contract wallets (ERC-1271)
 */
library SignatureVerifier {
    using ECDSA for bytes32;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant SET_AGENT_WALLET_TYPEHASH =
        keccak256("AgentWalletSet(uint256 agentId,address newWallet,address owner,uint256 deadline)");

    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    function computeDomainSeparator(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), chainId, verifyingContract)
        );
    }

    function hashSetAgentWallet(uint256 agentId, address newWallet, address owner, uint256 deadline)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(SET_AGENT_WALLET_TYPEHASH, agentId, newWallet, owner, deadline));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function verifySetAgentWallet(
        bytes32 domainSeparator,
        uint256 agentId,
        address newWallet,
        address owner,
        uint256 deadline,
        bytes memory signature
    ) internal view returns (bool) {
        if (block.timestamp > deadline) {
            return false;
        }

        bytes32 structHash = hashSetAgentWallet(agentId, newWallet, owner, deadline);
        bytes32 digest = toTypedDataHash(domainSeparator, structHash);

        if (newWallet.code.length > 0) {
            try IERC1271(newWallet).isValidSignature(digest, signature) returns (bytes4 magicValue) {
                return magicValue == ERC1271_MAGIC_VALUE;
            } catch {
                return false;
            }
        } else {
            address recoveredSigner = digest.recover(signature);
            return recoveredSigner == newWallet;
        }
    }
}
