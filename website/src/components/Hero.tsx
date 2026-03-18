"use client";

import { buttonVariants } from "@/components/ui/button";
import {
  GITHUB_REPO_URL,
  GITHUB_RELEASES_URL,
} from "@/lib/constants";
import { cn } from "@/lib/utils";

export function Hero() {
  const guideHref = "#guide";

  return (
    <section className="relative pt-28 pb-16 sm:pb-20 noise-bg overflow-hidden">
      <div className="relative z-10 max-w-5xl mx-auto px-4 sm:px-6">
        <div className="rounded-2xl border border-white/8 bg-gaming-surface/30 p-8 sm:p-10">
          <p className="font-mono text-xs uppercase tracking-[0.2em] text-gaming-cyan mb-4">
            Windows guide
          </p>
          <h1 className="font-heading text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight mb-5 leading-[1.05] max-w-4xl">
            Windows 11 Gaming Optimization Guide
          </h1>
          <p className="text-base sm:text-lg text-muted-foreground mb-8 max-w-2xl leading-relaxed">
            This is a script-based guide for Windows gaming tweaks, cleanup,
            revert steps, and verification. Read the guide first so you know
            which scripts fit your system and which ones carry tradeoffs.
          </p>
          <div className="flex flex-wrap gap-4">
            <a
              href={guideHref}
              className={cn(
                buttonVariants({ size: "lg" }),
                "bg-gaming-cyan hover:bg-gaming-cyan/90 text-black font-semibold px-6"
              )}
            >
              Read the guide
            </a>
            {GITHUB_RELEASES_URL && (
              <a
                href={GITHUB_RELEASES_URL}
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

          <div className="mt-8 border-t border-white/8 pt-6 max-w-2xl">
            <p className="text-sm text-muted-foreground leading-relaxed">
              Start with the guide, then use the launcher or the individual
              script folders based on what you actually want to change.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
