"use client";

import { buttonVariants } from "@/components/ui/button";
import { Terminal } from "@/components/Terminal";
import { GITHUB_REPO_URL, GITHUB_RELEASES_URL } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center grid-bg overflow-hidden">
      {/* Gradient glow */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gaming-cyan/10 rounded-full blur-[128px] pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gaming-magenta/10 rounded-full blur-[128px] pointer-events-none" />

      <div className="relative z-10 max-w-6xl mx-auto px-4 sm:px-6 pt-24 pb-16">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <h1 className="font-heading text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight mb-6">
              Maximum{" "}
              <span className="text-gaming-cyan">Gaming Performance</span> on
              Windows 11
            </h1>
            <p className="text-lg text-muted-foreground mb-8 max-w-lg">
              No bundled executables. No bloatware. No harmful tweaks. Just
              clean scripts you can read and verify yourself.
            </p>
            <div className="flex flex-wrap gap-4">
              <a
                href={GITHUB_RELEASES_URL}
                className={cn(
                  buttonVariants({ size: "lg" }),
                  "bg-gaming-green hover:bg-gaming-green/90 text-black font-semibold"
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
                  "border-gaming-cyan/30 text-gaming-cyan hover:bg-gaming-cyan/10"
                )}
              >
                View on GitHub
              </a>
            </div>
          </div>

          <div className="hidden lg:block">
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
