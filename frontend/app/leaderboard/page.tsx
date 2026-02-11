"use client";

import Link from "next/link";
import { Trophy } from "lucide-react";
import { useReadContract, useReadContracts } from "wagmi";
import { CONTRACTS } from "@/lib/contracts/addresses";
import {
  AgentIdentityRegistryABI,
  ReputationRegistryABI,
} from "@/lib/contracts/abis";

export default function LeaderboardPage() {
  const { data: totalSupply } = useReadContract({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "totalSupply",
  });

  const total = totalSupply ? Number(totalSupply) : 0;

  // Get all token IDs
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

  // Get owners + feedback counts for each agent
  const ownerContracts = agentIds.map((id) => ({
    address: CONTRACTS.agentIdentityRegistry,
    abi: AgentIdentityRegistryABI,
    functionName: "ownerOf" as const,
    args: [id],
  }));

  const feedbackContracts = agentIds.map((id) => ({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getFeedbackCount" as const,
    args: [id],
  }));

  const summaryContracts = agentIds.map((id) => ({
    address: CONTRACTS.reputationRegistry,
    abi: ReputationRegistryABI,
    functionName: "getSummary" as const,
    args: [id, [] as `0x${string}`[], "", ""],
  }));

  const { data: owners } = useReadContracts({
    contracts: ownerContracts,
    query: { enabled: agentIds.length > 0 },
  });

  const { data: feedbacks } = useReadContracts({
    contracts: feedbackContracts,
    query: { enabled: agentIds.length > 0 },
  });

  const { data: summaries } = useReadContracts({
    contracts: summaryContracts,
    query: { enabled: agentIds.length > 0 },
  });

  type AgentRow = {
    id: bigint;
    owner: string;
    feedbackCount: number;
    avgScore: number;
  };

  const rows: AgentRow[] = agentIds
    .map((id, i) => ({
      id,
      owner:
        owners?.[i]?.status === "success"
          ? (owners[i].result as string)
          : "...",
      feedbackCount:
        feedbacks?.[i]?.status === "success"
          ? Number(feedbacks[i].result as bigint)
          : 0,
      avgScore:
        summaries?.[i]?.status === "success"
          ? Number(
              (
                summaries[i].result as {
                  averageValue: bigint;
                }
              ).averageValue,
            )
          : 0,
    }))
    .sort((a, b) => b.avgScore - a.avgScore);

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-foreground flex items-center gap-3">
            <Trophy className="h-7 w-7 text-primary" />
            Leaderboard
          </h1>
          <p className="mt-2 text-muted-foreground">
            Agents ranked by reputation score
          </p>
        </div>

        {rows.length === 0 ? (
          <div className="bg-card/50 border border-border rounded-xl p-12 text-center">
            <p className="text-muted-foreground">
              No agents registered yet.
            </p>
          </div>
        ) : (
          <div className="bg-card/50 border border-border rounded-xl overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-6 py-4 text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Rank
                  </th>
                  <th className="px-6 py-4 text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Agent
                  </th>
                  <th className="px-6 py-4 text-xs font-medium text-muted-foreground uppercase tracking-wider hidden sm:table-cell">
                    Owner
                  </th>
                  <th className="px-6 py-4 text-xs font-medium text-muted-foreground uppercase tracking-wider text-right">
                    Feedback
                  </th>
                  <th className="px-6 py-4 text-xs font-medium text-muted-foreground uppercase tracking-wider text-right">
                    Avg Score
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.map((row, i) => (
                  <tr
                    key={row.id.toString()}
                    className="hover:bg-card/80 transition-colors"
                  >
                    <td className="px-6 py-4 text-sm text-muted-foreground">
                      {i + 1}
                    </td>
                    <td className="px-6 py-4">
                      <Link
                        href={`/agents/${row.id.toString()}`}
                        className="text-sm font-medium text-foreground hover:text-primary transition-colors"
                      >
                        Agent #{row.id.toString()}
                      </Link>
                    </td>
                    <td className="px-6 py-4 text-sm text-muted-foreground hidden sm:table-cell">
                      {row.owner !== "..."
                        ? `${row.owner.slice(0, 6)}...${row.owner.slice(-4)}`
                        : "..."}
                    </td>
                    <td className="px-6 py-4 text-sm text-foreground text-right">
                      {row.feedbackCount}
                    </td>
                    <td className="px-6 py-4 text-sm font-semibold text-right">
                      <span
                        className={
                          row.avgScore >= 0 ? "text-green-400" : "text-red-400"
                        }
                      >
                        {row.avgScore}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
