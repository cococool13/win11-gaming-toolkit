"use client";

import { buttonVariants } from "@/components/ui/button";
import {
  GITHUB_REPO_URL,
  GITHUB_RELEASES_URL,
} from "@/lib/constants";
import { cn } from "@/lib/utils";
import { Cpu, Gpu, RotateCcw, ShieldCheck } from "lucide-react";

const STATS = [
  { icon: Cpu, label: "Guide-first workflow" },
  { icon: Gpu, label: "GPU and network flows" },
  { icon: RotateCcw, label: "Tracked rollback path" },
  { icon: ShieldCheck, label: "Manifest-backed state" },
] as const;

const TERMINAL_LINES = [
  { type: "cmd", text: "PS> .\\launcher.ps1" },
  { type: "plain", text: "" },
  { type: "accent", text: "  WINDOWS 11 GAMING OPTIMIZATION" },
  { type: "accent", text: "  Primary entrypoint for setup, tuning, revert, and verification" },
  { type: "plain", text: "" },
  { type: "ok", text: "  [0]  Checkpoint          Restore point and registry backup" },
  { type: "ok", text: "  [2]  Power plan          Ultimate Performance and power tuning" },
  { type: "ok", text: "  [7]  Network             Adapter-aware optimization" },
  { type: "warn", text: "  [8]  Security trade-off  Disable VBS / Memory Integrity" },
  { type: "ok", text: "  [V]  Verify              Check what is applied now" },
  { type: "warn", text: "  [A]  Apply everything    Aggressive full-stack run" },
] as const;

export function Hero() {
  const guideHref = "#guide";

  return (
    <section className="relative pt-28 pb-8 sm:pb-12 noise-bg overflow-hidden">
      <div className="relative z-10 max-w-5xl mx-auto px-4 sm:px-6">
        {/* Main hero content */}
        <div className="grid gap-8 lg:grid-cols-[1fr,auto] lg:items-start">
          {/* Left — copy */}
          <div>
            <p className="font-mono text-xs uppercase tracking-[0.2em] text-gaming-cyan mb-4">
              Windows Optimization Toolkit
            </p>
            <h1 className="font-heading text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight mb-5 leading-[1.05] max-w-xl">
              <span className="gradient-text">Guide</span> first, then tune{" "}
              Windows 11 for gaming
            </h1>
            <p className="text-base sm:text-lg text-muted-foreground mb-8 max-w-lg leading-relaxed">
              One launcher, one guide, one rollback path. Start with the guide,
              use the launcher as the primary entrypoint, and verify changes
              after each tuning phase.
            </p>
            <div className="flex flex-wrap gap-3">
              <a
                href={guideHref}
                className={cn(
                  buttonVariants({ size: "lg" }),
                  "bg-gaming-cyan hover:bg-gaming-cyan/90 text-black font-semibold px-6 glow-btn"
                )}
              >
                Read the guide
              </a>
              {GITHUB_RELEASES_URL && (
                <a
                  href={GITHUB_RELEASES_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={cn(
                    buttonVariants({ variant: "outline", size: "lg" }),
                    "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-6"
                  )}
                >
                  Download
                </a>
              )}
              {GITHUB_REPO_URL && (
                <a
                  href={GITHUB_REPO_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={cn(
                    buttonVariants({ variant: "outline", size: "lg" }),
                    "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-6"
                  )}
                >
                  View source
                </a>
              )}
            </div>
          </div>

          {/* Right — terminal mockup */}
          <div className="terminal-window w-full lg:w-[340px] xl:w-[380px] shrink-0 hidden sm:block">
            <div className="terminal-header">
              <span className="terminal-dot bg-red-500/70" />
              <span className="terminal-dot bg-yellow-500/70" />
              <span className="terminal-dot bg-green-500/70" />
              <span className="ml-3 text-xs text-muted-foreground/60 font-mono">
                PowerShell
              </span>
            </div>
            <div className="terminal-body">
              {TERMINAL_LINES.map((line, i) => (
                <div key={i} className={line.type}>
                  {line.text || "\u00A0"}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Stats bar */}
        <div className="mt-10 pt-8 border-t border-white/6">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {STATS.map((stat) => {
              const Icon = stat.icon;
              return (
                <div
                  key={stat.label}
                  className="flex items-center gap-2.5 text-sm text-muted-foreground"
                >
                  <Icon className="w-4 h-4 text-gaming-cyan shrink-0" />
                  <span>{stat.label}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
