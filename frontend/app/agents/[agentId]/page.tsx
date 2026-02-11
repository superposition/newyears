"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import {
  ArrowLeft,
  Bot,
  MessageSquare,
  Shield,
  Star,
  Loader2,
  CheckCircle2,
  AlertCircle,
  Trash2,
  XCircle,
} from "lucide-react";
import { useState } from "react";
import { useAccount } from "wagmi";
import { fromHex } from "viem";
import {
  useAgentOwner,
  useAgentExists,
  useAgentURI,
  useAgentMetadata,
  useFeedbackCount,
  useReputationSummary,
  useAllFeedback,
  useAllValidations,
  useValidationCount,
  useGiveFeedback,
  useDeregisterAgent,
  useRevokeFeedback,
} from "@/lib/contracts/hooks";

export default function AgentDetailPage() {
  const params = useParams();
  const agentId = BigInt(params.agentId as string);
  const [tab, setTab] = useState<"feedback" | "validations">("feedback");

  const { address } = useAccount();
  const { data: exists } = useAgentExists(agentId);
  const { data: owner } = useAgentOwner(agentId);
  const { data: agentURI } = useAgentURI(agentId);
  const { data: nameBytes } = useAgentMetadata(agentId, "name");
  const { data: descBytes } = useAgentMetadata(agentId, "description");
  const { data: endpointBytes } = useAgentMetadata(agentId, "endpoint");
  const { data: capabilitiesBytes } = useAgentMetadata(agentId, "capabilities");
  const { data: feedbackCount } = useFeedbackCount(agentId);
  const { data: summary } = useReputationSummary(agentId);
  const { data: validationCount } = useValidationCount(agentId);
  const { data: feedbackList } = useAllFeedback(agentId);
  const { data: validations } = useAllValidations(agentId);

  const decodeMetadata = (bytes: string | undefined) => {
    if (!bytes || bytes === "0x") return "";
    try { return fromHex(bytes as `0x${string}`, "string"); } catch { return ""; }
  };

  const agentName = decodeMetadata(nameBytes as string);
  const agentDesc = decodeMetadata(descBytes as string);
  const agentEndpoint = decodeMetadata(endpointBytes as string);
  const agentCapabilities = decodeMetadata(capabilitiesBytes as string);

  const ownerStr = owner
    ? `${(owner as string).slice(0, 6)}...${(owner as string).slice(-4)}`
    : "...";
  const avgRep = summary ? Number(summary.averageValue) : 0;
  const fCount = feedbackCount ? Number(feedbackCount) : 0;
  const vCount = validationCount ? Number(validationCount) : 0;

  const isOwner =
    address && owner && address.toLowerCase() === (owner as string).toLowerCase();

  // Feedback form state
  const [fbValue, setFbValue] = useState(0);
  const [fbTag1, setFbTag1] = useState("");
  const [fbTag2, setFbTag2] = useState("");
  const [fbComment, setFbComment] = useState("");

  const {
    write: giveFeedback,
    isPending: fbPending,
    isConfirming: fbConfirming,
    isConfirmed: fbConfirmed,
    error: fbError,
  } = useGiveFeedback();

  const {
    write: deregister,
    isPending: deregPending,
    isConfirming: deregConfirming,
    isConfirmed: deregConfirmed,
    error: deregError,
  } = useDeregisterAgent();

  const {
    write: revokeFeedback,
    isPending: revokePending,
    isConfirming: revokeConfirming,
    isConfirmed: revokeConfirmed,
    error: revokeError,
  } = useRevokeFeedback();

  const handleFeedbackSubmit = () => {
    giveFeedback(agentId, BigInt(fbValue), fbTag1, fbTag2, fbComment);
  };

  const handleDeregister = () => {
    if (confirm("Are you sure you want to deregister this agent? This action cannot be undone.")) {
      deregister(agentId);
    }
  };

  const handleRevoke = (feedbackIndex: bigint) => {
    revokeFeedback(agentId, feedbackIndex);
  };

  const fbBusy = fbPending || fbConfirming;
  const deregBusy = deregPending || deregConfirming;
  const revokeBusy = revokePending || revokeConfirming;

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Back */}
        <Link
          href="/agents"
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-primary transition-colors mb-8"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Agents
        </Link>

        {/* Header */}
        <div className="flex items-start justify-between mb-8">
          <div className="flex items-start gap-4">
            <div className="h-14 w-14 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-xl font-bold text-white flex-shrink-0">
              <Bot className="h-7 w-7" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-foreground">
                {agentName || `Agent #${agentId.toString()}`}
              </h1>
              <p className="text-sm text-muted-foreground mt-1">
                {owner ? (owner as string) : "Loading..."}
              </p>
              {exists !== undefined && (
                <span
                  className={`inline-flex items-center mt-2 px-2 py-0.5 rounded-full text-xs font-medium ${
                    exists
                      ? "bg-green-500/10 text-green-400 border border-green-500/20"
                      : "bg-red-500/10 text-red-400 border border-red-500/20"
                  }`}
                >
                  {exists ? "Active" : "Not Found"}
                </span>
              )}
            </div>
          </div>

          {isOwner && exists && (
            <button
              onClick={handleDeregister}
              disabled={deregBusy || deregConfirmed}
              className="px-4 py-2 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm font-medium hover:bg-red-500/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {deregBusy ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : deregConfirmed ? (
                <CheckCircle2 className="h-4 w-4" />
              ) : (
                <Trash2 className="h-4 w-4" />
              )}
              {deregPending
                ? "Confirm..."
                : deregConfirming
                  ? "Waiting..."
                  : deregConfirmed
                    ? "Deregistered"
                    : "Deregister"}
            </button>
          )}
        </div>

        {deregError && (
          <div className="flex items-start gap-4 p-4 rounded-lg bg-red-500/10 border border-red-500/20 mb-6">
            <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-red-200">
              {(deregError as Error).message?.split("\n")[0] ?? "Deregister failed"}
            </p>
          </div>
        )}

        {/* Agent Info */}
        {exists && (agentDesc || agentEndpoint || agentCapabilities || agentURI) && (
          <div className="bg-card/50 border border-border rounded-xl p-6 mb-6 space-y-3">
            {agentDesc && (
              <p className="text-sm text-foreground">{agentDesc}</p>
            )}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              {agentEndpoint && (
                <div>
                  <span className="text-muted-foreground">API Endpoint: </span>
                  <code className="text-primary bg-primary/10 px-1.5 py-0.5 rounded text-xs">
                    {agentEndpoint}
                  </code>
                </div>
              )}
              {agentCapabilities && (
                <div>
                  <span className="text-muted-foreground">Capabilities: </span>
                  <span className="text-foreground">{agentCapabilities}</span>
                </div>
              )}
              {agentURI && (
                <div className="sm:col-span-2">
                  <span className="text-muted-foreground">Metadata URI: </span>
                  <span className="text-foreground break-all text-xs">{agentURI as string}</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Stat cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-10">
          <div className="bg-card/50 border border-border rounded-xl p-5">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <MessageSquare className="h-4 w-4" />
              <span className="text-sm">Feedback</span>
            </div>
            <p className="text-2xl font-bold text-foreground">{fCount}</p>
          </div>
          <div className="bg-card/50 border border-border rounded-xl p-5">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <Star className="h-4 w-4" />
              <span className="text-sm">Avg Reputation</span>
            </div>
            <p className="text-2xl font-bold text-foreground">{avgRep}</p>
          </div>
          <div className="bg-card/50 border border-border rounded-xl p-5">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <Shield className="h-4 w-4" />
              <span className="text-sm">Validations</span>
            </div>
            <p className="text-2xl font-bold text-foreground">{vCount}</p>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 border-b border-border mb-6">
          <button
            onClick={() => setTab("feedback")}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px ${
              tab === "feedback"
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            Feedback
          </button>
          <button
            onClick={() => setTab("validations")}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px ${
              tab === "validations"
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            Validations
          </button>
        </div>

        {/* Tab content */}
        {tab === "feedback" && (
          <div className="space-y-3">
            {revokeError && (
              <div className="flex items-start gap-4 p-4 rounded-lg bg-red-500/10 border border-red-500/20">
                <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-red-200">
                  {(revokeError as Error).message?.split("\n")[0] ?? "Revoke failed"}
                </p>
              </div>
            )}
            {revokeConfirmed && (
              <div className="flex items-start gap-4 p-4 rounded-lg bg-green-500/10 border border-green-500/20">
                <CheckCircle2 className="h-5 w-5 text-green-400 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-green-200">Feedback revoked successfully.</p>
              </div>
            )}

            {feedbackList && feedbackList.length > 0 ? (
              feedbackList.map((fb, i) => (
                <div
                  key={i}
                  className="bg-card/50 border border-border rounded-xl p-5"
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs text-muted-foreground">
                      {`${fb.client.slice(0, 6)}...${fb.client.slice(-4)}`}
                    </span>
                    <div className="flex items-center gap-3">
                      <span
                        className={`text-sm font-semibold ${
                          Number(fb.value) >= 0 ? "text-green-400" : "text-red-400"
                        }`}
                      >
                        {Number(fb.value) >= 0 ? "+" : ""}
                        {Number(fb.value)}
                      </span>
                      {address &&
                        fb.client.toLowerCase() === address.toLowerCase() &&
                        !fb.isRevoked && (
                          <button
                            onClick={() => handleRevoke(BigInt(fb.feedbackIndex))}
                            disabled={revokeBusy}
                            className="text-xs text-red-400 hover:text-red-300 transition-colors disabled:opacity-50 flex items-center gap-1"
                            title="Revoke this feedback"
                          >
                            {revokeBusy ? (
                              <Loader2 className="h-3 w-3 animate-spin" />
                            ) : (
                              <XCircle className="h-3 w-3" />
                            )}
                            Revoke
                          </button>
                        )}
                    </div>
                  </div>
                  {fb.isRevoked && (
                    <span className="text-xs text-red-400 italic">Revoked</span>
                  )}
                  {fb.comment && (
                    <p className="text-sm text-foreground">{fb.comment}</p>
                  )}
                  <div className="flex gap-2 mt-2">
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
                  </div>
                </div>
              ))
            ) : (
              <p className="text-muted-foreground text-sm py-8 text-center">
                No feedback yet for this agent.
              </p>
            )}
          </div>
        )}

        {tab === "validations" && (
          <div className="space-y-3">
            {validations && validations.length > 0 ? (
              validations.map((v, i) => (
                <div
                  key={i}
                  className="bg-card/50 border border-border rounded-xl p-5"
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs text-muted-foreground">
                      Validator: {`${v.validatorAddress.slice(0, 6)}...${v.validatorAddress.slice(-4)}`}
                    </span>
                    <span
                      className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                        v.response === 1
                          ? "bg-green-500/10 text-green-400"
                          : v.response === 2
                            ? "bg-red-500/10 text-red-400"
                            : "bg-yellow-500/10 text-yellow-400"
                      }`}
                    >
                      {v.response === 1
                        ? "Passed"
                        : v.response === 2
                          ? "Failed"
                          : "Pending"}
                    </span>
                  </div>
                  {v.tag && (
                    <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary">
                      {v.tag}
                    </span>
                  )}
                </div>
              ))
            ) : (
              <p className="text-muted-foreground text-sm py-8 text-center">
                No validations yet for this agent.
              </p>
            )}
          </div>
        )}

        {/* Give Feedback Section */}
        {exists && (
          <div className="mt-10">
            <h2 className="text-xl font-semibold text-foreground mb-4">
              Give Feedback
            </h2>
            <div className="bg-card/50 border border-border rounded-xl p-6 space-y-4">
              {!address && (
                <div className="flex items-start gap-4 p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
                  <AlertCircle className="h-5 w-5 text-yellow-400 flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-yellow-200">
                    Connect your wallet to give feedback.
                  </p>
                </div>
              )}

              <div>
                <label className="text-sm font-medium text-foreground mb-2 block">
                  Value ({fbValue})
                </label>
                <input
                  type="range"
                  min={-100}
                  max={100}
                  value={fbValue}
                  onChange={(e) => setFbValue(Number(e.target.value))}
                  className="w-full accent-primary"
                />
                <div className="flex justify-between text-xs text-muted-foreground mt-1">
                  <span>-100</span>
                  <span>0</span>
                  <span>+100</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-foreground mb-2 block">
                    Tag 1
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., quality"
                    value={fbTag1}
                    onChange={(e) => setFbTag1(e.target.value)}
                    className="w-full px-4 py-2 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-foreground mb-2 block">
                    Tag 2
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., speed"
                    value={fbTag2}
                    onChange={(e) => setFbTag2(e.target.value)}
                    className="w-full px-4 py-2 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
                  />
                </div>
              </div>

              <div>
                <label className="text-sm font-medium text-foreground mb-2 block">
                  Comment
                </label>
                <textarea
                  placeholder="Share your experience with this agent..."
                  value={fbComment}
                  onChange={(e) => setFbComment(e.target.value)}
                  rows={3}
                  className="w-full px-4 py-2 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary resize-none text-sm"
                />
              </div>

              {fbError && (
                <div className="flex items-start gap-4 p-4 rounded-lg bg-red-500/10 border border-red-500/20">
                  <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-red-200">
                    {(fbError as Error).message?.split("\n")[0] ?? "Feedback failed"}
                  </p>
                </div>
              )}

              {fbConfirmed && (
                <div className="flex items-start gap-4 p-4 rounded-lg bg-green-500/10 border border-green-500/20">
                  <CheckCircle2 className="h-5 w-5 text-green-400 flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-green-200">
                    Feedback submitted successfully!
                  </p>
                </div>
              )}

              <button
                onClick={handleFeedbackSubmit}
                disabled={!address || fbBusy || fbConfirmed}
                className="w-full px-6 py-3 rounded-lg bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all glow-border disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {fbPending && (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Confirm in Wallet...
                  </>
                )}
                {fbConfirming && (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Waiting for Block...
                  </>
                )}
                {fbConfirmed && (
                  <>
                    <CheckCircle2 className="h-4 w-4" />
                    Submitted
                  </>
                )}
                {!fbPending && !fbConfirming && !fbConfirmed && "Submit Feedback"}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
