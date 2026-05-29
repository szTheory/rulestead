import type { Metadata } from "next";
import type { CSSProperties, ReactNode } from "react";

export const metadata: Metadata = {
  title: "FleetDesk · Rulestead adoption lab",
  description:
    "Minimal fleet-ops host app exercising Rulestead rollouts, experiments, remote config, explain, and kill-switch journeys.",
};

const bodyStyle: CSSProperties = {
  margin: 0,
  minHeight: "100vh",
  background:
    "radial-gradient(circle at top, rgba(247, 201, 72, 0.22), transparent 35%), linear-gradient(180deg, #f6efe4 0%, #efe2cf 100%)",
  color: "#1e1a16",
  fontFamily:
    '"Iowan Old Style", "Palatino Linotype", "Book Antiqua", Georgia, serif',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body style={bodyStyle}>{children}</body>
    </html>
  );
}
