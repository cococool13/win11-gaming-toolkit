"use client";

import { Separator } from "@/components/ui/separator";
import { GITHUB_REPO_URL } from "@/lib/constants";

export function Footer() {
  return (
    <footer className="py-8 border-t border-white/5">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>
            <p className="font-mono text-sm font-semibold text-gaming-cyan">
              Win11 Gaming Toolkit
            </p>
            <p className="text-xs text-muted-foreground">
              Based on optimizations by{" "}
              <strong className="text-foreground">Khorvie Tech</strong>
            </p>
          </div>

          <div className="flex items-center gap-5 text-xs text-muted-foreground">
            <a
              href={GITHUB_REPO_URL}
              className="hover:text-foreground transition-colors"
            >
              GitHub
            </a>
            <Separator orientation="vertical" className="h-3" />
            <a
              href={`${GITHUB_REPO_URL}/blob/main/GUIDE.md`}
              className="hover:text-foreground transition-colors"
            >
              Guide
            </a>
            <Separator orientation="vertical" className="h-3" />
            <a
              href={`${GITHUB_REPO_URL}/blob/main/BIOS-CHECKLIST.md`}
              className="hover:text-foreground transition-colors"
            >
              BIOS Checklist
            </a>
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground/60 mt-6">
          Free, open, no strings.
        </p>
      </div>
    </footer>
  );
}
