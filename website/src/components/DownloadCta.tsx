"use client";

import { buttonVariants } from "@/components/ui/button";
import { ScrollReveal } from "./ScrollReveal";
import { GITHUB_RELEASES_URL, GITHUB_REPO_URL } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function DownloadCta() {
  return (
    <section id="download" className="py-28 relative">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 text-center">
        <ScrollReveal variant="blur">
          <h2 className="font-heading text-3xl sm:text-5xl font-bold mb-4">
            <span className="gradient-text">Download</span>
          </h2>
          <p className="text-muted-foreground mb-10 max-w-md mx-auto">
            Extract, right-click APPLY-EVERYTHING.ps1, run as Admin.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href={GITHUB_RELEASES_URL}
              className={cn(
                buttonVariants({ size: "lg" }),
                "bg-gaming-green hover:bg-gaming-green/90 text-black font-semibold px-8 text-base"
              )}
            >
              Download Latest Release
            </a>
            <a
              href={GITHUB_REPO_URL}
              target="_blank"
              rel="noopener noreferrer"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-8 text-base"
              )}
            >
              View Source
            </a>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
