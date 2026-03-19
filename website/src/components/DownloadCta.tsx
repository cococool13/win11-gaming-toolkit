"use client";

import { buttonVariants } from "@/components/ui/button";
import { ScrollReveal } from "./ScrollReveal";
import { GITHUB_RELEASES_URL, GITHUB_REPO_URL } from "@/lib/constants";
import { cn } from "@/lib/utils";
import { Download, Github, BookOpen, Settings } from "lucide-react";

const LINKS = [
  {
    label: "Read Guide",
    href: GITHUB_REPO_URL ? `${GITHUB_REPO_URL}/blob/main/GUIDE.md` : "",
    icon: BookOpen,
    primary: true,
  },
  {
    label: "Download",
    href: GITHUB_RELEASES_URL ?? "",
    icon: Download,
    primary: false,
  },
  {
    label: "View Source",
    href: GITHUB_REPO_URL ?? "",
    icon: Github,
    primary: false,
  },
  {
    label: "BIOS Checklist",
    href: GITHUB_REPO_URL
      ? `${GITHUB_REPO_URL}/blob/main/BIOS-CHECKLIST.md`
      : "",
    icon: Settings,
    primary: false,
  },
] as const;

export function DownloadCta() {
  const availableLinks = LINKS.filter((link) => link.href !== "");

  if (availableLinks.length === 0) return null;

  return (
    <section className="py-16 section-surface relative">
      <div className="section-divider" />
      <div className="max-w-4xl mx-auto px-4 sm:px-6 pt-16 text-center">
        <ScrollReveal variant="blur">
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-4">
            Get started
          </h2>
          <p className="text-muted-foreground mb-10 max-w-2xl mx-auto">
            Start with the guide, then download and run the scripts that match
            your system.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            {availableLinks.map((link) => {
              const Icon = link.icon;
              return (
                <a
                  key={link.label}
                  href={link.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={cn(
                    buttonVariants({
                      variant: link.primary ? "default" : "outline",
                      size: "lg",
                    }),
                    link.primary
                      ? "bg-gaming-cyan hover:bg-gaming-cyan/90 text-black font-semibold px-8 text-base glow-btn"
                      : "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 px-8 text-base"
                  )}
                >
                  <Icon className="w-4 h-4 mr-2" />
                  {link.label}
                </a>
              );
            })}
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
