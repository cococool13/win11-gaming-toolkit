"use client";

import { buttonVariants } from "@/components/ui/button";
import { Terminal } from "@/components/Terminal";
import { GITHUB_REPO_URL, GITHUB_RELEASES_URL, HERO_STATS } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center noise-bg overflow-hidden">
      <div className="relative z-10 max-w-6xl mx-auto px-4 sm:px-6 pt-24 pb-16 w-full">
        <div className="grid lg:grid-cols-[1.2fr_1fr] gap-12 lg:gap-16 items-center">
          <div>
            <h1 className="font-heading text-5xl sm:text-6xl lg:text-7xl font-bold tracking-tight mb-6 leading-[1.05]">
              Optimize{" "}
              <span className="gradient-text">Win11.</span>
            </h1>
            <p className="text-lg text-muted-foreground mb-8 max-w-md">
              One script. More FPS, less bloat, cleaner desktop.
              Fully reversible.
            </p>
            <div className="flex flex-wrap gap-4 mb-8">
              <a
                href={GITHUB_RELEASES_URL}
                className={cn(
                  buttonVariants({ size: "lg" }),
                  "bg-gaming-green hover:bg-gaming-green/90 text-black font-semibold px-6"
                )}
              >
                Download Toolkit
              </a>
              <a
                href={GITHUB_REPO_URL}
                target="_blank"
                rel="noopener noreferrer"
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                  "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-6"
                )}
              >
                View Source
              </a>
            </div>

            {/* Inline trust stats */}
            <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-muted-foreground">
              {HERO_STATS.map((stat, i) => (
                <span key={stat} className="flex items-center gap-4">
                  {i > 0 && (
                    <span className="text-white/15 select-none" aria-hidden>
                      /
                    </span>
                  )}
                  {stat}
                </span>
              ))}
            </div>
          </div>

          <div className="hidden md:block -rotate-1 translate-y-2">
            <Terminal
              typing
              lines={[
                {
                  text: "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser",
                  color: "text-muted-foreground",
                },
                {
                  text: ".\\APPLY-EVERYTHING.ps1",
                  color: "text-gaming-green",
                },
              ]}
            />
          </div>
        </div>
      </div>
    </section>
  );
}
