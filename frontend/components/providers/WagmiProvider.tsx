"use client";

import { ReactNode } from "react";
import { RainbowKitProvider, darkTheme } from "@rainbow-me/rainbowkit";
import { WagmiProvider, createConfig, http } from "wagmi";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import { injected } from "wagmi/connectors";
import { roax } from "@/lib/chains/roax";
import "@rainbow-me/rainbowkit/styles.css";

// Simple config without WalletConnect - works with MetaMask, Coinbase, etc.
const config = createConfig({
  chains: [roax],
  connectors: [
    injected({ target: "metaMask" }),
    injected({ target: "coinbaseWallet" }),
    injected({ target: "trust" }),
  ],
  transports: {
    [roax.id]: http(),
  },
  ssr: true,
});

const queryClient = new QueryClient();

export function Providers({ children }: { children: ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          theme={darkTheme({
            accentColor: "#ec4899",
            accentColorForeground: "white",
            borderRadius: "large",
            fontStack: "system",
          })}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
