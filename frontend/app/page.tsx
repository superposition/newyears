"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Search, ArrowRight, Plus, Bot } from "lucide-react";
import { useState } from "react";
import { useLatestAgents } from "@/lib/contracts/hooks";

export default function Home() {
  const [query, setQuery] = useState("");
  const router = useRouter();
  const { agents, total } = useLatestAgents(5);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (query.trim()) {
      router.push(`/agents?search=${encodeURIComponent(query.trim())}`);
    }
  }

  return (
    <div className="w-full">
      {/* Hero */}
      <section className="py-32 md:py-44">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col items-center text-center">
            <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight leading-tight">
              Discover AI Agents on{" "}
              <span className="gradient-text">ERC-8004</span>
            </h1>
            <p className="mt-4 text-lg text-muted-foreground max-w-xl">
              Explore, validate, and interact with AI agents registered on the
              ROAX network
            </p>

            {/* Search */}
            <form onSubmit={handleSearch} className="mt-10 w-full max-w-xl">
              <div className="wave-border">
                <div className="relative bg-card rounded-[calc(0.75rem-2px)]">
                  <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <input
                    type="text"
                    placeholder="Search agents by ID or address..."
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    className="w-full pl-12 pr-4 py-4 rounded-[calc(0.75rem-2px)] bg-transparent text-foreground placeholder:text-muted-foreground focus:outline-none transition-all"
                  />
                </div>
              </div>
            </form>

            {/* Buttons */}
            <div className="mt-6 flex flex-col sm:flex-row gap-3">
              <Link
                href="/agents"
                className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg bg-primary text-primary-foreground font-semibold hover:bg-primary/80 transition-all"
              >
                Browse Agents
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                href="/create"
                className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg bg-card border border-border text-foreground font-semibold hover:bg-card/80 hover:border-primary/50 transition-all"
              >
                <Plus className="h-4 w-4" />
                Create Agent
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Latest Agents */}
      <section className="pb-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-foreground flex items-center gap-2">
              <Bot className="h-6 w-6 text-primary" />
              Latest Agents
            </h2>
            <p className="mt-1 text-sm text-muted-foreground">
              New autonomous agents entering the ecosystem
            </p>
          </div>

          {total === 0 ? (
            <div className="bg-card/50 border border-border rounded-xl p-12 text-center">
              <Bot className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground mb-4">
                No agents registered yet. Be the first!
              </p>
              <Link
                href="/create"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all"
              >
                <Plus className="h-4 w-4" />
                Create Agent
              </Link>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
              {agents.map((agent) => (
                <Link
                  key={agent.id.toString()}
                  href={`/agents/${agent.id.toString()}`}
                  className="bg-card/50 border border-border rounded-xl p-5 hover:border-primary/50 transition-all group"
                >
                  <div className="h-10 w-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-sm font-bold text-white mb-3">
                    #{agent.id.toString()}
                  </div>
                  <h3 className="text-sm font-semibold text-foreground group-hover:text-primary transition-colors truncate">
                    Agent #{agent.id.toString()}
                  </h3>
                  <p className="text-xs text-muted-foreground mt-1 truncate">
                    {agent.owner
                      ? `${agent.owner.slice(0, 6)}...${agent.owner.slice(-4)}`
                      : "Loading..."}
                  </p>
                  <p className="text-xs text-muted-foreground mt-2">
                    {agent.feedbackCount} feedback
                  </p>
                </Link>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
