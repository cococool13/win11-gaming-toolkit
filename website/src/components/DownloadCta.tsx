"use client";

import { buttonVariants } from "@/components/ui/button";
import { ScrollReveal } from "./ScrollReveal";
import { GITHUB_RELEASES_URL, GITHUB_REPO_URL } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function DownloadCta() {
  const hasRepo = Boolean(GITHUB_REPO_URL);
  const hasReleases = Boolean(GITHUB_RELEASES_URL);
  const hasGuide = hasRepo;
  const hasBios = hasRepo;

  return (
    <section className="py-16 relative">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 text-center">
        <ScrollReveal variant="blur">
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-4">
            Links
          </h2>
          <p className="text-muted-foreground mb-10 max-w-2xl mx-auto">
            Use the guide as the starting point. Download and source links are
            secondary. The file list above shows which script to open or run.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            {hasGuide && (
              <a
                href={`${GITHUB_REPO_URL}/blob/main/GUIDE.md`}
                target="_blank"
                rel="noopener noreferrer"
                className={cn(
                  buttonVariants({ size: "lg" }),
                  "bg-gaming-cyan hover:bg-gaming-cyan/90 text-black font-semibold px-8 text-base"
                )}
              >
                Read Guide
              </a>
            )}
            {hasReleases && (
              <a
                href={GITHUB_RELEASES_URL}
                target="_blank"
                rel="noopener noreferrer"
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                  "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-8 text-base"
                )}
              >
                Download
              </a>
            )}
            {hasRepo && (
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
            )}
            {hasBios && (
              <a
                href={`${GITHUB_REPO_URL}/blob/main/BIOS-CHECKLIST.md`}
                target="_blank"
                rel="noopener noreferrer"
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                  "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-8 text-base"
                )}
              >
                BIOS Checklist
              </a>
            )}
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
