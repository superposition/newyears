# Frontend Setup & Deployment Guide

## 🎉 Status: Complete

The ERC-8004 Trustless Agents frontend is **fully built and ready for deployment**!

## What's Included

### ✅ Completed Features

1. **Homepage** (`/`)
   - Clean landing page with feature highlights
   - PLASMA staking information
   - Navigation to register and browse agents
   - RainbowKit wallet connection

2. **Agent Registration** (`/register`)
   - Two-step approval and registration flow
   - 0.1 PLASMA token approval
   - Agent URI and metadata input (name, description)
   - Transaction status tracking
   - Success confirmation

3. **Agent Discovery** (`/agents`)
   - Browse all registered agents
   - ERC721Enumerable integration
   - Agent cards with name, owner, URI
   - Links to detail pages

4. **Agent Detail Page** (`/agents/[agentId]`)
   - Complete agent information
   - Owner identification
   - Reputation dashboard (count, average, min, max)
   - Give feedback form (score slider, tags, comment)
   - Non-owner feedback restriction

### 🛠️ Tech Stack

- **Next.js 16.1.6** - React framework with App Router
- **TypeScript** - Type-safe development
- **RainbowKit 2.2.10** - Wallet connection with 100+ wallet support
- **wagmi 2.19.5** - React Hooks for Ethereum
- **viem 2.45.2** - TypeScript Ethereum library
- **Tailwind CSS 4.1.18** - Utility-first CSS framework
- **@tailwindcss/postcss 4.1.18** - PostCSS plugin for Tailwind v4

### 📁 Project Structure

```
frontend/
├── app/
│   ├── layout.tsx               # Root layout with providers
│   ├── page.tsx                 # Homepage
│   ├── globals.css              # Global styles
│   ├── register/
│   │   └── page.tsx            # Agent registration
│   └── agents/
│       ├── page.tsx            # Agent list (static)
│       └── [agentId]/
│           └── page.tsx        # Agent detail (dynamic SSR)
├── components/
│   └── providers/
│       └── WagmiProvider.tsx    # Wagmi + RainbowKit setup
├── lib/
│   ├── chains/
│   │   └── roax.ts             # ROAX chain definition (chainId 135)
│   └── contracts/
│       ├── abis.ts             # Contract ABI exports
│       ├── addresses.ts        # Contract addresses (UPDATE AFTER DEPLOYMENT)
│       └── abis/               # Raw ABI JSON files
├── next.config.ts               # Next.js configuration
├── tsconfig.json                # TypeScript configuration
├── postcss.config.js            # PostCSS with Tailwind plugin
├── firebase.json                # Firebase Hosting config
├── .firebaserc                  # Firebase project config
├── package.json                 # Dependencies
├── DEPLOYMENT.md                # Detailed deployment guide
└── README.md                    # Frontend documentation
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Update Contract Addresses

After deploying smart contracts to ROAX:

```bash
# Check deployment addresses
cat ../deployments-135.json
```

Update `lib/contracts/addresses.ts`:

```typescript
export const contractAddresses = {
  plasmaToken: '0xYourPlasmaTokenAddress',
  stakingManager: '0xYourStakingManagerAddress',
  identityRegistry: '0xYourIdentityRegistryAddress',
  reputationRegistry: '0xYourReputationRegistryAddress',
  validationRegistry: '0xYourValidationRegistryAddress',
} as const;
```

### 3. Get WalletConnect Project ID

1. Visit https://cloud.walletconnect.com/
2. Create a new project
3. Copy the Project ID
4. Update `components/providers/WagmiProvider.tsx`:

```typescript
const config = getDefaultConfig({
  appName: 'ERC-8004 Trustless Agents on ROAX',
  projectId: 'YOUR_WALLETCONNECT_PROJECT_ID', // <- Paste here
  chains: [roaxChain],
  ssr: false,
});
```

### 4. Run Development Server

```bash
npm run dev
# Open http://localhost:3000
```

## 🔥 Firebase Deployment

### Option 1: Firebase Hosting + Cloud Functions (Recommended)

For full SSR support with dynamic routes:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not done)
firebase init hosting
# Select: Functions + Hosting

# Update .firebaserc with your project ID
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}

# Build Next.js
npm run build

# Deploy to Firebase
firebase deploy
```

#### Firebase Configuration for Next.js SSR

Update `firebase.json`:

```json
{
  "hosting": {
    "public": ".next",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "function": "nextjsApp"
      }
    ]
  },
  "functions": {
    "source": ".",
    "runtime": "nodejs18"
  }
}
```

Create `functions/index.js`:

```javascript
const {onRequest} = require("firebase-functions/v2/https");
const next = require("next");

const server = next({
  dev: false,
  conf: {
    distDir: ".next",
  },
});

const nextjsHandle = server.getRequestHandler();

exports.nextjsApp = onRequest(async (req, res) => {
  await server.prepare();
  return nextjsHandle(req, res);
});
```

### Option 2: Vercel (Easiest)

Vercel is the platform made by the Next.js team and has zero-config deployment:

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Follow prompts to link to your project
```

### Option 3: Self-Hosted

```bash
# Build for production
npm run build

# Start production server
npm run start

# Or use PM2 for process management
npm install -g pm2
pm2 start npm --name "erc8004-frontend" -- start
```

## 📋 Pre-Deployment Checklist

- [ ] Smart contracts deployed to ROAX network (chainId 135)
- [ ] Contract addresses updated in `lib/contracts/addresses.ts`
- [ ] WalletConnect Project ID added to `WagmiProvider.tsx`
- [ ] Firebase project created (if using Firebase)
- [ ] `.firebaserc` updated with project ID
- [ ] `npm install` completed successfully
- [ ] `npm run build` succeeds without errors
- [ ] Test locally with `npm run dev`
- [ ] Deploy with `firebase deploy` or `vercel`

## 🔗 ROAX Network Configuration

The app is pre-configured for ROAX Network:

```typescript
// lib/chains/roax.ts
export const roaxChain = defineChain({
  id: 135,
  name: 'ROAX Network',
  rpcUrls: {
    default: { http: ['https://devrpc.roax.net'] },
  },
  nativeCurrency: {
    name: 'PLASMA',
    symbol: 'PLASMA',
    decimals: 18,
  },
  testnet: true,
});
```

RainbowKit will automatically prompt users to add the ROAX network to their wallet when connecting.

## 🧪 Testing

### Manual Testing Steps

1. **Connect Wallet**
   - Click "Connect Wallet" button
   - Select a wallet (MetaMask recommended)
   - Approve ROAX network addition
   - Verify wallet shows PLASMA balance

2. **Register Agent**
   - Navigate to `/register`
   - Step 1: Approve 0.1 PLASMA tokens
   - Wait for approval confirmation
   - Step 2: Enter agent URI and optional metadata
   - Submit registration
   - Verify success message

3. **Browse Agents**
   - Navigate to `/agents`
   - Verify agent cards display
   - Check agent count badge
   - Click an agent card

4. **Agent Detail & Feedback**
   - Verify agent information displays
   - Check reputation summary (0 reviews initially)
   - If not owner: Submit feedback
   - Adjust score slider (-100 to 100)
   - Add tags and comment
   - Submit feedback transaction
   - Verify reputation updates

## 📊 Build Output

```
Route (app)
┌ ○ /                    Static page
├ ○ /agents              Static page
├ ƒ /agents/[agentId]    Dynamic SSR
└ ○ /register            Static page

○  (Static)   prerendered as static content
ƒ  (Dynamic)  server-rendered on demand
```

## 🐛 Troubleshooting

### "Network not found" in wallet

1. Manually add ROAX network:
   - Network Name: ROAX Network
   - RPC URL: https://devrpc.roax.net
   - Chain ID: 135
   - Currency Symbol: PLASMA

### Contract addresses are zeros

Update `lib/contracts/addresses.ts` after deploying contracts.

### Build fails with type errors

```bash
rm -rf node_modules package-lock.json .next
npm install
npm run build
```

### WalletConnect errors

Get a valid Project ID from https://cloud.walletconnect.com/

## 📖 Documentation

- `README.md` - Frontend overview and features
- `DEPLOYMENT.md` - Detailed deployment instructions
- `../README.md` - Smart contract documentation

## 🎯 Next Steps

1. **Deploy Smart Contracts**
   ```bash
   cd ..
   forge script script/DeployToRoax.s.sol \
     --rpc-url $ROAX_RPC_URL \
     --broadcast \
     --legacy
   ```

2. **Update Frontend Addresses**
   ```bash
   cat deployments-135.json
   # Copy addresses to frontend/lib/contracts/addresses.ts
   ```

3. **Get WalletConnect Project ID**
   - Visit https://cloud.walletconnect.com/
   - Create project and copy ID

4. **Deploy Frontend**
   ```bash
   cd frontend
   npm run build
   firebase deploy  # or vercel
   ```

5. **Test End-to-End**
   - Connect wallet
   - Register an agent
   - Submit feedback
   - Verify reputation updates

## 🙏 Support

- Firebase Docs: https://firebase.google.com/docs/hosting
- Next.js Docs: https://nextjs.org/docs
- RainbowKit Docs: https://rainbowkit.com/
- wagmi Docs: https://wagmi.sh/
- ERC-8004 Spec: https://eips.ethereum.org/EIPS/eip-8004

---

**Status**: ✅ Production Ready
**Last Updated**: 2026-02-11
