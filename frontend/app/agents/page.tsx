"use client";

import Link from "next/link";
import { Search, Bot, Plus } from "lucide-react";
import { useState } from "react";
import { useLatestAgents } from "@/lib/contracts/hooks";

export default function AgentsPage() {
  const [searchQuery, setSearchQuery] = useState("");
  const { agents, total } = useLatestAgents(50);

  const filtered = searchQuery.trim()
    ? agents.filter(
        (a) =>
          a.id.toString().includes(searchQuery) ||
          a.owner?.toLowerCase().includes(searchQuery.toLowerCase()),
      )
    : agents;

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Header */}
        <div className="mb-10">
          <h1 className="text-3xl font-bold gradient-text">Explore Agents</h1>
          <p className="mt-2 text-muted-foreground">
            {total} agents registered on the ROAX network
          </p>
        </div>

        {/* Search */}
        <div className="mb-8">
          <div className="relative max-w-xl">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search by agent ID or owner address..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-3 rounded-xl bg-card border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary transition-all"
            />
          </div>
        </div>

        {/* Agent Grid */}
        {filtered.length === 0 ? (
          <div className="bg-card/50 border border-border rounded-xl p-12 text-center">
            <Bot className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <p className="text-muted-foreground mb-4">
              {total === 0
                ? "No agents found. Be the first to create one!"
                : "No agents match your search."}
            </p>
            {total === 0 && (
              <Link
                href="/create"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all"
              >
                <Plus className="h-4 w-4" />
                Create Agent
              </Link>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {filtered.map((agent) => (
              <Link
                key={agent.id.toString()}
                href={`/agents/${agent.id.toString()}`}
                className="bg-card/50 border border-border rounded-xl p-6 hover:border-primary/50 transition-all group"
              >
                <div className="h-12 w-12 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-sm font-bold text-white mb-4">
                  #{agent.id.toString()}
                </div>
                <h3 className="text-base font-semibold text-foreground group-hover:text-primary transition-colors">
                  Agent #{agent.id.toString()}
                </h3>
                <p className="text-sm text-muted-foreground mt-1">
                  {agent.owner
                    ? `${agent.owner.slice(0, 6)}...${agent.owner.slice(-4)}`
                    : "Loading..."}
                </p>
                <p className="text-xs text-muted-foreground mt-3">
                  {agent.feedbackCount} feedback
                </p>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
