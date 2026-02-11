"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAccount } from "wagmi";
import { Sparkles, AlertCircle, Loader2, CheckCircle2 } from "lucide-react";
import { useRegisterAgent } from "@/lib/contracts/hooks";
import { toHex } from "viem";

export default function CreatePage() {
  const router = useRouter();
  const { isConnected } = useAccount();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    uri: "",
    capabilities: "",
  });

  const {
    write: registerAgent,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  } = useRegisterAgent();

  const handleRegister = () => {
    const metadata: { key: string; value: `0x${string}` }[] = [];

    if (formData.name) {
      metadata.push({ key: "name", value: toHex(formData.name) });
    }
    if (formData.description) {
      metadata.push({ key: "description", value: toHex(formData.description) });
    }
    if (formData.capabilities) {
      metadata.push({ key: "capabilities", value: toHex(formData.capabilities) });
    }

    registerAgent(formData.uri, metadata);
  };

  const txBusy = isPending || isConfirming;

  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Header */}
        <div className="max-w-3xl mx-auto mb-10">
          <h1 className="text-3xl font-bold gradient-text">Create Agent</h1>
          <p className="mt-2 text-muted-foreground">
            Register your AI agent on the ROAX network
          </p>
        </div>

        {/* Steps */}
        <div className="max-w-3xl mx-auto mb-10">
          <div className="flex items-center justify-between">
            {[1, 2].map((s) => (
              <div key={s} className="flex items-center flex-1">
                <div
                  className={`flex items-center justify-center w-10 h-10 rounded-full font-semibold transition-all ${
                    step >= s
                      ? "bg-primary text-primary-foreground"
                      : "bg-muted text-muted-foreground"
                  }`}
                >
                  {s}
                </div>
                {s < 2 && (
                  <div
                    className={`flex-1 h-1 mx-2 transition-all ${
                      step > s ? "bg-primary" : "bg-muted"
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
          <div className="flex justify-between mt-2">
            <span className="text-sm text-muted-foreground">Agent Info</span>
            <span className="text-sm text-muted-foreground">Confirm</span>
          </div>
        </div>

        {/* Form */}
        <div className="max-w-3xl mx-auto">
          <div className="bg-card/50 border border-border rounded-xl p-8">
            {step === 1 && (
              <div className="space-y-6">
                <div>
                  <label className="text-sm font-medium text-foreground mb-2 block">
                    Agent Name *
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., CodeAssistant AI"
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <div>
                  <label className="text-sm font-medium text-foreground mb-2 block">
                    Description *
                  </label>
                  <textarea
                    placeholder="Describe your agent's capabilities and purpose..."
                    value={formData.description}
                    onChange={(e) =>
                      setFormData({ ...formData, description: e.target.value })
                    }
                    rows={4}
                    className="w-full px-4 py-3 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                  />
                </div>

                <div>
                  <label className="text-sm font-medium text-foreground mb-2 block">
                    Metadata URI *
                  </label>
                  <input
                    type="text"
                    placeholder="ipfs://..."
                    value={formData.uri}
                    onChange={(e) =>
                      setFormData({ ...formData, uri: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                  <p className="text-sm text-muted-foreground mt-2">
                    IPFS URI pointing to your agent&apos;s metadata JSON
                  </p>
                </div>

                <div>
                  <label className="text-sm font-medium text-foreground mb-2 block">
                    Capabilities (Optional)
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., coding, analysis, automation"
                    value={formData.capabilities}
                    onChange={(e) =>
                      setFormData({ ...formData, capabilities: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-background border border-border text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>

                <button
                  onClick={() => setStep(2)}
                  disabled={!formData.name || !formData.description || !formData.uri}
                  className="w-full px-6 py-3 rounded-lg bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all glow-border disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Continue
                </button>
              </div>
            )}

            {step === 2 && (
              <div className="space-y-6">
                <div className="space-y-4">
                  <h3 className="text-xl font-semibold text-foreground">
                    Confirm Registration
                  </h3>

                  <div className="space-y-3 p-4 rounded-lg bg-background">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Name:</span>
                      <span className="text-foreground font-medium">{formData.name}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Stake:</span>
                      <span className="text-foreground font-medium">0.1 PLASMA</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Network:</span>
                      <span className="text-foreground font-medium">ROAX (135)</span>
                    </div>
                  </div>

                  <div className="flex items-start gap-4 p-4 rounded-lg bg-primary/10 border border-primary/20">
                    <Sparkles className="h-5 w-5 text-primary flex-shrink-0 mt-0.5" />
                    <p className="text-sm text-foreground">
                      Your agent will be minted as an ERC-721 NFT and registered on-chain.
                      0.1 PLASMA will be sent with the transaction as a stake.
                      No separate approval step is needed.
                    </p>
                  </div>

                  {!isConnected && (
                    <div className="flex items-start gap-4 p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
                      <AlertCircle className="h-5 w-5 text-yellow-400 flex-shrink-0 mt-0.5" />
                      <p className="text-sm text-yellow-200">
                        Please connect your wallet to register an agent.
                      </p>
                    </div>
                  )}

                  {error && (
                    <div className="flex items-start gap-4 p-4 rounded-lg bg-red-500/10 border border-red-500/20">
                      <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5" />
                      <p className="text-sm text-red-200">
                        {(error as Error).message?.split("\n")[0] ?? "Transaction failed"}
                      </p>
                    </div>
                  )}

                  {isConfirmed && hash && (
                    <div className="flex items-start gap-4 p-4 rounded-lg bg-green-500/10 border border-green-500/20">
                      <CheckCircle2 className="h-5 w-5 text-green-400 flex-shrink-0 mt-0.5" />
                      <div className="text-sm text-green-200">
                        <p className="font-medium">Agent registered successfully!</p>
                        <button
                          onClick={() => router.push("/agents")}
                          className="underline hover:text-green-100 mt-1"
                        >
                          View all agents
                        </button>
                      </div>
                    </div>
                  )}
                </div>

                <div className="flex gap-4">
                  <button
                    onClick={() => setStep(1)}
                    disabled={txBusy}
                    className="flex-1 px-6 py-3 rounded-lg bg-card border border-border text-foreground font-semibold hover:bg-card/80 transition-all disabled:opacity-50"
                  >
                    Back
                  </button>
                  <button
                    onClick={handleRegister}
                    disabled={!isConnected || txBusy || isConfirmed}
                    className="flex-1 px-6 py-3 rounded-lg bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all glow-border disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    {isPending && (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Confirm in Wallet...
                      </>
                    )}
                    {isConfirming && (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Waiting for Block...
                      </>
                    )}
                    {isConfirmed && (
                      <>
                        <CheckCircle2 className="h-4 w-4" />
                        Registered
                      </>
                    )}
                    {!isPending && !isConfirming && !isConfirmed && "Register Agent"}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
