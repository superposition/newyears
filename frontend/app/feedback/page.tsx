"use client";

import Link from "next/link";
import { MessageSquare } from "lucide-react";
import { useReadContract, useReadContracts } from "wagmi";
import { CONTRACTS } from "@/lib/contracts/addresses";
import {
  AgentIdentityRegistryABI,
  ReputationRegistryABI,
} from "@/lib/contracts/abis";

type FeedbackEntry = {
  client: string;
  agent: bigint;
  value: bigint;
  valueDecimals: number;
  tag1: string;
  tag2: string;
  comment: string;
  timestamp: bigint;
  isRevoked: boolean;
  feedbackIndex: bigint;
};

export default function FeedbackPage() {
  const { data: totalSupply } = useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "totalSupply",
  });

  const total = totalSupply ? Number(totalSupply) : 0;

  const tokenIdContracts = Array.from({ length: total }, (_, i) => ({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "tokenByIndex" as const,
    args: [BigInt(i)],
  }));

  const { data: tokenIdResults } = useReadContracts({
    contracts: tokenIdContracts,
    query: { enabled: total > 0 },
  });

  const agentIds =
    tokenIdResults
      ?.map((r) => (r.status === "success" ? (r.result as bigint) : null))
      .filter((id): id is bigint => id !== null) ?? [];

  // Get all feedback for each agent
  const feedbackContracts = agentIds.map((id) => ({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getAllFeedback" as const,
    args: [id, false],
  }));

  const { data: allFeedbackResults } = useReadContracts({
    contracts: feedbackContracts,
    query: { enabled: agentIds.length > 0 },
  });

  // Flatten all feedback entries, sorted by timestamp descending
  const allFeedback: (FeedbackEntry & { agentId: bigint })[] = [];
  allFeedbackResults?.forEach((result, i) => {
    if (result.status === "success" && Array.isArray(result.result)) {
      (result.result as FeedbackEntry[]).forEach((fb) => {
        allFeedback.push({ ...fb, agentId: agentIds[i] });
      });
    }
  });

  allFeedback.sort((a, b) => Number(b.timestamp) - Number(a.timestamp));

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-3">
            <MessageSquare className="h-7 w-7 text-primary" />
            Recent Feedback
          </h1>
          <p className="mt-2 text-muted-foreground">
            Latest feedback across all agents
          </p>
        </div>

        {allFeedback.length === 0 ? (
          <div className="bg-card/50 border border-border rounded-xl p-12 text-center">
            <p className="text-muted-foreground">
              No feedback has been submitted yet.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {allFeedback.map((fb, i) => (
              <div
                key={i}
                className="bg-card/50 border border-border rounded-xl p-5"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                    <Link
                      href={`/agents/${fb.agentId.toString()}`}
                      className="text-sm font-medium text-foreground hover:text-primary transition-colors"
                    >
                      Agent #{fb.agentId.toString()}
                    </Link>
                    <span className="text-xs text-muted-foreground">
                      by {`${fb.client.slice(0, 6)}...${fb.client.slice(-4)}`}
                    </span>
                  </div>
                  <span
                    className={`text-sm font-semibold ${
                      Number(fb.value) >= 0 ? "text-green-400" : "text-red-400"
                    }`}
                  >
                    {Number(fb.value) >= 0 ? "+" : ""}
                    {Number(fb.value)}
                  </span>
                </div>
                {fb.comment && (
                  <p className="text-sm text-foreground">{fb.comment}</p>
                )}
                <div className="flex items-center gap-2 mt-2">
                  {fb.tag1 && (
                    <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary">
                      {fb.tag1}
                    </span>
                  )}
                  {fb.tag2 && (
                    <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary">
                      {fb.tag2}
                    </span>
                  )}
                  <span className="text-xs text-muted-foreground ml-auto">
                    {fb.timestamp
                      ? new Date(Number(fb.timestamp) * 1000).toLocaleDateString()
                      : ""}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
