import { Chain } from "viem";

export const roax: Chain = {
  id: 135,
  name: "ROAX Network",
  nativeCurrency: {
    name: "PLASMA",
    symbol: "PLASMA",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["https://devrpc.roax.net"],
    },
    public: {
      http: ["https://devrpc.roax.net"],
    },
  },
  blockExplorers: {
    default: {
      name: "ROAX Explorer",
      url: "https://explorer.roax.net",
    },
  },
  testnet: false,
};
