"use client";

import { Separator } from "@/components/ui/separator";
import { GITHUB_REPO_URL } from "@/lib/constants";

export function Footer() {
  return (
    <footer className="py-12 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-6">
          <div>
            <p className="font-heading font-semibold text-gaming-cyan mb-1">
              Win11 Gaming Toolkit
            </p>
            <p className="text-sm text-muted-foreground">
              Based on optimizations by{" "}
              <strong className="text-foreground">Khorvie Tech</strong>
            </p>
          </div>

          <div className="flex items-center gap-6 text-sm text-muted-foreground">
            <a
              href={GITHUB_REPO_URL}
              className="hover:text-foreground transition-colors"
            >
              GitHub
            </a>
            <Separator orientation="vertical" className="h-4" />
            <a
              href={`${GITHUB_REPO_URL}/blob/main/GUIDE.md`}
              className="hover:text-foreground transition-colors"
            >
              Guide
            </a>
            <Separator orientation="vertical" className="h-4" />
            <a
              href={`${GITHUB_REPO_URL}/blob/main/BIOS-CHECKLIST.md`}
              className="hover:text-foreground transition-colors"
            >
              BIOS Checklist
            </a>
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-8">
          Built for the community. Share freely.
        </p>
      </div>
    </footer>
  );
}
