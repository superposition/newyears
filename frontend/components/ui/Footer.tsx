export default function Footer() {
  return (
    <footer className="w-full border-t border-border/40 bg-card/30 backdrop-blur">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-muted-foreground">
            8004scan &mdash; ERC-8004 Explorer on ROAX Network
          </p>
          <div className="flex items-center gap-6">
            <a
              href="https://eips.ethereum.org/EIPS/eip-8004"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-muted-foreground hover:text-primary transition-colors"
            >
              ERC-8004 Spec
            </a>
            <a
              href="https://roax.net"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-muted-foreground hover:text-primary transition-colors"
            >
              ROAX Network
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
