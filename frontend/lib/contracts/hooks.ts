"use client";

import {
  useReadContract,
  useReadContracts,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseEther } from "viem";
import { CONTRACTS } from "./addresses";
import {
  AgentIdentityRegistryABI,
  ReputationRegistryABI,
  ValidationRegistryABI,
} from "./abis";

export function useTotalAgents() {
  return useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "totalSupply",
  });
}

export function useAgentOwner(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "ownerOf",
    args: [agentId],
  });
}

export function useAgentURI(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "getAgentURI",
    args: [agentId],
  });
}

export function useAgentExists(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "exists",
    args: [agentId],
  });
}

export function useFeedbackCount(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getFeedbackCount",
    args: [agentId],
  });
}

export function useAllFeedback(agentId: bigint, includeRevoked = false) {
  return useReadContract({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getAllFeedback",
    args: [agentId, includeRevoked],
  });
}

export function useReputationSummary(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getSummary",
    args: [agentId, [], "", ""],
  });
}

export function useValidationCount(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.validationRegistry,
    abi: ValidationRegistryABI,
    functionName: "getValidationCount",
    args: [agentId],
  });
}

export function useAllValidations(agentId: bigint) {
  return useReadContract({
    address: CONTRACTS.validationRegistry,
    abi: ValidationRegistryABI,
    functionName: "getAllValidations",
    args: [agentId],
  });
}

export function useLatestAgents(count: number) {
  const { data: totalSupply, ...rest } = useTotalAgents();
  const total = totalSupply ? Number(totalSupply) : 0;
  const agentCount = Math.min(count, total);

  const contracts = Array.from({ length: agentCount }, (_, i) => {
    const index = total - 1 - i;
    return [
      {
        address: CONTRACTS.agentIdentityRegistry,
        abi: AgentIdentityRegistryABI,
        functionName: "tokenByIndex" as const,
        args: [BigInt(index)],
      },
    ];
  }).flat();

  const { data: tokenIds } = useReadContracts({
    contracts,
    query: { enabled: agentCount > 0 },
  });

  const agentIds =
    tokenIds
      ?.map((r) => (r.status === "success" ? (r.result as bigint) : null))
      .filter((id): id is bigint => id !== null) ?? [];

  const ownerContracts = agentIds.map((id) => ({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "ownerOf" as const,
    args: [id],
  }));

  const uriContracts = agentIds.map((id) => ({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "getAgentURI" as const,
    args: [id],
  }));

  const feedbackContracts = agentIds.map((id) => ({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getFeedbackCount" as const,
    args: [id],
  }));

  const nameContracts = agentIds.map((id) => ({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "getMetadata" as const,
    args: [id, "name"],
  }));

  const { data: owners } = useReadContracts({
    contracts: ownerContracts,
    query: { enabled: agentIds.length > 0 },
  });

  const { data: uris } = useReadContracts({
    contracts: uriContracts,
    query: { enabled: agentIds.length > 0 },
  });

  const { data: feedbacks } = useReadContracts({
    contracts: feedbackContracts,
    query: { enabled: agentIds.length > 0 },
  });

  const { data: names } = useReadContracts({
    contracts: nameContracts,
    query: { enabled: agentIds.length > 0 },
  });

  const agents = agentIds.map((id, i) => ({
    id,
    owner:
      owners?.[i]?.status === "success"
        ? (owners[i].result as `0x${string}`)
        : undefined,
    uri:
      uris?.[i]?.status === "success"
        ? (uris[i].result as string)
        : undefined,
    name:
      names?.[i]?.status === "success"
        ? (names[i].result as `0x${string}`)
        : undefined,
    feedbackCount:
      feedbacks?.[i]?.status === "success"
        ? Number(feedbacks[i].result as bigint)
        : 0,
  }));

  return { agents, total, ...rest };
}

export function useAgentMetadata(agentId: bigint, key: string) {
  return useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "getMetadata",
    args: [agentId, key],
  });
}

// ── Write Hooks ──

export function useRegisterAgent() {
  const {
    writeContract,
    data: hash,
    isPending,
    error,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({ hash });

  const write = (
    uri: string,
    metadata: { key: string; value: `0x${string}` }[]
  ) => {
    writeContract({
      address: CONTRACTS.agentIdentityRegistry,
      abi: AgentIdentityRegistryABI,
      functionName: "register",
      args: [uri, metadata],
      value: parseEther("0.1"),
    });
  };

  return { write, hash, isPending, isConfirming, isConfirmed, error };
}

export function useDeregisterAgent() {
  const {
    writeContract,
    data: hash,
    isPending,
    error,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({ hash });

  const write = (agentId: bigint) => {
    writeContract({
      address: CONTRACTS.agentIdentityRegistry,
      abi: AgentIdentityRegistryABI,
      functionName: "deregister",
      args: [agentId],
    });
  };

  return { write, hash, isPending, isConfirming, isConfirmed, error };
}

export function useGiveFeedback() {
  const {
    writeContract,
    data: hash,
    isPending,
    error,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({ hash });

  const write = (
    agentId: bigint,
    value: bigint,
    tag1: string,
    tag2: string,
    comment: string
  ) => {
    writeContract({
      address: CONTRACTS.reputationRegistry,
      abi: ReputationRegistryABI,
      functionName: "giveFeedback",
      args: [agentId, value, 0, tag1, tag2, comment],
    });
  };

  return { write, hash, isPending, isConfirming, isConfirmed, error };
}

export function useRevokeFeedback() {
  const {
    writeContract,
    data: hash,
    isPending,
    error,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({ hash });

  const write = (agentId: bigint, feedbackIndex: bigint) => {
    writeContract({
      address: CONTRACTS.reputationRegistry,
      abi: ReputationRegistryABI,
      functionName: "revokeFeedback",
      args: [agentId, feedbackIndex],
    });
  };

  return { write, hash, isPending, isConfirming, isConfirmed, error };
}
