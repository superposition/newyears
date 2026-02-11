# 🚀 Quick Start Guide

## Installation

```bash
cd frontend
npm install
```

## Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see your pink-themed ERC-8004 explorer!

## What You'll See

### 🌌 Space Canvas
- Animated starfield with twinkling pink stars
- Occasional shooting stars with gradient trails
- Beautiful deep space background

### 📄 Pages

1. **Landing Page** (`/`)
   - Hero section with animated elements
   - Stats dashboard (ready for real data)
   - Feature cards explaining ERC-8004
   - "How It Works" section
   - Call-to-action section

2. **Explore Agents** (`/agents`)
   - Search and filter functionality
   - Agent cards with stats
   - Reputation indicators
   - Mock data (replace with contract reads)

3. **Create Agent** (`/create`)
   - 3-step registration flow
   - PLASMA token approval
   - Agent information form
   - Confirmation screen

## 🎨 Pink Theme Highlights

- **Primary Color**: Vibrant pink (`#ec4899`)
- **Gradient Effects**: Pink to purple gradients
- **Glow Animations**: Pulsing glow effects on buttons and cards
- **Shooting Stars**: Pink gradient trails
- **Typography**: Clean, modern fonts with gradient text

## 📁 Key Files

- `components/space/SpaceCanvas.tsx` - Space animation
- `app/page.tsx` - Landing page
- `app/agents/page.tsx` - Agent browsing
- `app/create/page.tsx` - Agent creation
- `tailwind.config.ts` - Pink theme configuration

## 🔧 Customization

### Change Colors
Edit `tailwind.config.ts`:
```typescript
primary: {
  DEFAULT: "hsl(330, 85%, 55%)", // Change this
  foreground: "hsl(0, 0%, 100%)",
},
```

### Adjust Star Animation
Edit `components/space/SpaceCanvas.tsx`:
```typescript
const numStars = 200; // More or fewer stars
const maxShootingStars = 3; // Shooting star frequency
```

## ✨ Features

✅ Animated space canvas with shooting stars
✅ Pink color theme throughout
✅ Responsive design
✅ Beautiful animations and transitions
✅ Mock data for testing UI
✅ Ready for Web3 integration

## 🔜 Next Steps

To connect to smart contracts:

1. Uncomment RainbowKit provider in layout
2. Add wagmi hooks for reading contract data
3. Implement wallet connection
4. Replace mock data with real contract reads
5. Add transaction flows

## 🎯 No Networks Tab

As requested, there's no networks tab - the site is specifically for ROAX Network (Chain ID 135) only.

Enjoy your pink-themed space explorer! 🌟
