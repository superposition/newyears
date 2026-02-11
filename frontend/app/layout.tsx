import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import SpaceCanvas from "@/components/space/SpaceCanvas";
import Header from "@/components/ui/Header";
import Footer from "@/components/ui/Footer";
import { Providers } from "@/components/providers/WagmiProvider";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "ERC-8004 Explorer | ROAX Network",
  description: "Explore and interact with trustless AI agents on ROAX blockchain using ERC-8004 standard",
  openGraph: {
    title: "ERC-8004 Explorer | ROAX Network",
    description: "Explore and interact with trustless AI agents on ROAX blockchain",
    images: ["/og-image.png"],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          <SpaceCanvas />
          <div className="relative z-10 flex flex-col min-h-screen w-full mx-auto">
            <Header />
            <main className="flex-1">{children}</main>
            <Footer />
          </div>
        </Providers>
      </body>
    </html>
  );
}
