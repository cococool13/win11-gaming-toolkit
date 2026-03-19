import type { Metadata } from "next";
import { Inter, Space_Grotesk, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Win11 Gaming Toolkit — Windows 11 Gaming Optimization Guide",
  description:
    "A guide-first homepage for Windows 11 gaming scripts, setup steps, revert paths, and verification tools.",
  openGraph: {
    title: "Win11 Gaming Toolkit",
    description:
      "Windows 11 gaming guide with script-based tweaks, revert tools, and verification steps.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${inter.variable} ${spaceGrotesk.variable} ${jetbrainsMono.variable} antialiased`}
      >
        <a href="#guide" className="skip-nav">Skip to content</a>
        <noscript>
          <style>{`.reveal-up,.reveal-left,.reveal-right,.reveal-blur{opacity:1;transform:none;filter:none}`}</style>
        </noscript>
        {children}
      </body>
    </html>
  );
}
