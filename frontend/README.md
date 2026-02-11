# ERC-8004 Explorer - Pink Space Theme

A beautiful pink-themed explorer for ERC-8004 trustless AI agents on the ROAX network, featuring an animated space canvas with shooting stars.

## Features

✨ **Space Canvas Animation**
- Animated starfield background with twinkling stars
- Occasional shooting stars with pink gradient trails
- Pink color palette throughout

🎨 **Design**
- Inspired by 8004scan.io with custom pink theme
- Responsive layout for all devices
- Beautiful gradient effects and glow animations
- Smooth transitions and hover effects

🔗 **Pages**
- **Landing Page**: Hero section with stats, features, and how it works
- **Explore Agents**: Browse and search registered agents
- **Create Agent**: Multi-step agent registration form
- **Agent Details**: View agent info, reputation, and feedback (coming soon)

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn/pnpm
- MetaMask or another Web3 wallet

### Installation

```bash
cd frontend
npm install
```

### Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build for Production

```bash
npm run build
npm start
```

## Tech Stack

- **Next.js 15** - React framework
- **TypeScript** - Type safety
- **Tailwind CSS 4** - Utility-first styling
- **Lucide Icons** - Beautiful icons
- **Canvas API** - Space animation

## Color Theme

The pink theme uses the following color palette:

- **Primary**: `hsl(330, 85%, 55%)` - Vibrant pink
- **Secondary**: `hsl(310, 70%, 45%)` - Deep purple-pink
- **Accent**: `hsl(340, 80%, 60%)` - Hot pink
- **Background**: `hsl(330, 30%, 4%)` - Dark purple-black
- **Card**: `hsl(330, 25%, 8%)` - Slightly lighter dark

## Project Structure

```
frontend/
├── app/
│   ├── page.tsx              # Landing page
│   ├── agents/
│   │   └── page.tsx          # Browse agents
│   ├── create/
│   │   └── page.tsx          # Create agent
│   ├── layout.tsx            # Root layout
│   └── globals.css           # Global styles
├── components/
│   ├── space/
│   │   └── SpaceCanvas.tsx   # Animated space background
│   └── ui/
│       ├── Header.tsx        # Navigation header
│       └── Footer.tsx        # Site footer
├── lib/                      # Utilities and configs
└── public/                   # Static assets
```

## Customization

### Changing Colors

Edit `tailwind.config.ts` to modify the pink theme colors.

### Adjusting Space Animation

Modify `components/space/SpaceCanvas.tsx` to adjust:
- Number of stars
- Shooting star frequency
- Animation speeds
- Color gradients

## Next Steps

To integrate with smart contracts:

1. Add RainbowKit wallet connection
2. Add wagmi hooks for contract interactions
3. Connect to deployed contracts on ROAX
4. Implement agent registration flow
5. Add agent browsing with real data
6. Implement feedback and validation features

## License

MIT

## Credits

Design inspired by [8004scan.io](https://www.8004scan.io/) with a custom pink theme for the ROAX network.

Built with ❤️ for the ERC-8004 ecosystem.
