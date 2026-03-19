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
  title: "Win11 Gaming Toolkit — Guide-First Windows 11 Tuning",
  description:
    "Guide-first landing page for the Windows 11 gaming optimization toolkit, launcher, rollback path, and verification report.",
  openGraph: {
    title: "Win11 Gaming Toolkit",
    description:
      "Windows 11 tuning toolkit with one launcher, one guide, one rollback path, and a verification report.",
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
