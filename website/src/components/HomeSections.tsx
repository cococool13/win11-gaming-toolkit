"use client";

import { buttonVariants } from "@/components/ui/button";
import {
  FILE_LINKS,
  INCLUDED_SECTIONS,
  QUICK_START_STEPS,
} from "@/lib/constants";
import { cn } from "@/lib/utils";
import { ScrollReveal } from "./ScrollReveal";
import {
  BookOpen,
  ShieldCheck,
  Play,
  HardDrive,
  Zap,
  Wrench,
  Gpu,
  Undo2,
  AlertTriangle,
  Star,
} from "lucide-react";

const STEP_ICONS = [BookOpen, ShieldCheck, Play] as const;

const INCLUDED_ICONS = [HardDrive, Zap, Wrench, Gpu, Undo2] as const;

export function QuickStartSection() {
  return (
    <section id="guide" className="py-16 section-surface">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-3">
            Quick start
          </h2>
          <p className="text-muted-foreground max-w-2xl mb-10">
            The website is only an overview. GUIDE.md is the source of truth,
            and launcher.ps1 is the main entrypoint for the toolkit.
          </p>
        </ScrollReveal>

        <div className="grid gap-4 md:grid-cols-3">
          {QUICK_START_STEPS.map((step, index) => {
            const Icon = STEP_ICONS[index];
            return (
              <ScrollReveal
                key={step.title}
                delay={index * 70}
                className="rounded-xl border border-white/8 bg-gaming-surface/35 p-6 hover:border-gaming-cyan/20 transition-colors"
              >
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-8 h-8 rounded-lg bg-gaming-cyan/10 flex items-center justify-center">
                    <Icon className="w-4 h-4 text-gaming-cyan" />
                  </div>
                  <p className="font-mono text-xs text-gaming-cyan">
                    Step {index + 1}
                  </p>
                </div>
                <h3 className="font-heading text-lg font-semibold mb-2">
                  {step.title}
                </h3>
                <p className="text-sm text-muted-foreground leading-relaxed">
                  {step.description}
                </p>
              </ScrollReveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export function IncludedSection() {
  return (
    <section id="included" className="py-16">
      <div className="section-divider" />
      <div className="max-w-5xl mx-auto px-4 sm:px-6 pt-16">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-3">
            What&apos;s included
          </h2>
          <p className="text-muted-foreground max-w-2xl mb-10">
            The repo is organized around a few clear surfaces so you can
            understand the workflow before you touch the lower-level files.
          </p>
        </ScrollReveal>

        <div className="grid gap-4 md:grid-cols-2">
          {INCLUDED_SECTIONS.map((section, index) => {
            const Icon = INCLUDED_ICONS[index] ?? Wrench;
            return (
              <ScrollReveal
                key={section.title}
                delay={index * 60}
                className="rounded-xl border border-white/8 bg-gaming-surface/25 p-6 hover:border-white/15 transition-colors"
              >
                <div className="flex items-start gap-4">
                  <div className="w-9 h-9 rounded-lg bg-gaming-surface-light flex items-center justify-center shrink-0 mt-0.5">
                    <Icon className="w-4 h-4 text-gaming-cyan" />
                  </div>
                  <div>
                    <h3 className="font-heading text-lg font-semibold mb-2">
                      {section.title}
                    </h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {section.description}
                    </p>
                  </div>
                </div>
              </ScrollReveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export function FilesSection() {
  return (
    <section className="py-16 section-surface">
      <div className="section-divider" />
      <div className="max-w-5xl mx-auto px-4 sm:px-6 pt-16">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-3">
            Files and scripts
          </h2>
          <p className="text-muted-foreground max-w-2xl mb-10">
            These are the main files worth opening or running directly. Start
            with the guide, then use the launcher or a specific phase script.
          </p>
        </ScrollReveal>

        <div className="grid gap-4">
          {FILE_LINKS.map((item, index) => {
            const isFeatured = index <= 1; // GUIDE.md and launcher.ps1
            return (
              <ScrollReveal
                key={item.path}
                delay={index * 50}
                className={cn(
                  "rounded-xl border p-5 sm:p-6 transition-colors",
                  isFeatured
                    ? "featured-card border-gaming-cyan/20"
                    : "border-white/8 bg-gaming-surface/25 hover:border-white/15"
                )}
              >
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div className="max-w-2xl">
                    <div className="flex items-center gap-2 mb-2">
                      {isFeatured && (
                        <Star className="w-3.5 h-3.5 text-gaming-cyan fill-gaming-cyan/30" />
                      )}
                      <h3 className="font-heading text-lg font-semibold">
                        {item.title}
                      </h3>
                    </div>
                    <p className="font-mono text-xs text-gaming-cyan mb-3">
                      {item.path}
                    </p>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {item.instruction}
                    </p>
                  </div>
                  {item.href ? (
                    <a
                      href={item.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={cn(
                        buttonVariants({ variant: "outline" }),
                        "border-white/10 text-muted-foreground hover:text-foreground hover:bg-white/5 shrink-0"
                      )}
                    >
                      Open file
                    </a>
                  ) : (
                    <span className="text-xs text-muted-foreground/70 shrink-0 sm:pt-1">
                      Link available when repo URL is configured
                    </span>
                  )}
                </div>
              </ScrollReveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export function TradeoffsSection() {
  return (
    <section className="py-16">
      <div className="section-divider" />
      <div className="max-w-5xl mx-auto px-4 sm:px-6 pt-16">
        <ScrollReveal>
          <div className="rounded-2xl warning-card border p-7 sm:p-8">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-lg bg-gaming-yellow/10 flex items-center justify-center shrink-0 mt-0.5">
                <AlertTriangle className="w-5 h-5 text-gaming-yellow" />
              </div>
              <div>
                <h2 className="font-heading text-2xl sm:text-3xl font-bold mb-4">
                  Safety and tradeoffs
                </h2>
                <div className="space-y-3 text-sm sm:text-base text-muted-foreground leading-relaxed max-w-3xl">
                  <p>
                    Some scripts are aggressive and are not the right fit for
                    every PC.
                  </p>
                  <p>
                    The rollback path is strongest when you use the launcher
                    and full-stack scripts, because those flows record more
                    state.
                  </p>
                  <p>
                    Read the guide before running everything, especially on
                    laptops, hybrid-GPU systems, or machines that do more than
                    gaming.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
