import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "hsl(330, 30%, 4%)",
        foreground: "hsl(320, 90%, 98%)",
        card: "hsl(330, 25%, 8%)",
        "card-foreground": "hsl(320, 90%, 98%)",
        popover: "hsl(330, 25%, 8%)",
        "popover-foreground": "hsl(320, 90%, 98%)",
        primary: {
          DEFAULT: "hsl(330, 85%, 55%)",
          foreground: "hsl(0, 0%, 100%)",
        },
        secondary: {
          DEFAULT: "hsl(310, 70%, 45%)",
          foreground: "hsl(0, 0%, 100%)",
        },
        muted: {
          DEFAULT: "hsl(330, 20%, 15%)",
          foreground: "hsl(320, 60%, 80%)",
        },
        accent: {
          DEFAULT: "hsl(340, 80%, 60%)",
          foreground: "hsl(0, 0%, 100%)",
        },
        destructive: {
          DEFAULT: "hsl(0, 62.8%, 30.6%)",
          foreground: "hsl(0, 85.7%, 97.3%)",
        },
        border: "hsl(330, 30%, 18%)",
        input: "hsl(330, 30%, 18%)",
        ring: "hsl(330, 85%, 55%)",
      },
      borderRadius: {
        lg: "1rem",
        md: "0.75rem",
        sm: "0.5rem",
      },
      animation: {
        "shooting-star": "shooting-star 3s linear infinite",
        "twinkle": "twinkle 2s ease-in-out infinite",
        "float": "float 6s ease-in-out infinite",
        "glow": "glow 2s ease-in-out infinite alternate",
      },
      keyframes: {
        "shooting-star": {
          "0%": { transform: "translateX(0) translateY(0) rotate(45deg)", opacity: "1" },
          "70%": { opacity: "1" },
          "100%": { transform: "translateX(-500px) translateY(500px) rotate(45deg)", opacity: "0" },
        },
        twinkle: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.3" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-20px)" },
        },
        glow: {
          "0%": { boxShadow: "0 0 20px rgba(236, 72, 153, 0.3)" },
          "100%": { boxShadow: "0 0 40px rgba(236, 72, 153, 0.6)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
