"use client";

import { buttonVariants } from "@/components/ui/button";
import {
  FILE_LINKS,
  INCLUDED_SECTIONS,
  QUICK_START_STEPS,
} from "@/lib/constants";
import { cn } from "@/lib/utils";
import { ScrollReveal } from "./ScrollReveal";

export function QuickStartSection() {
  return (
    <section id="guide" className="py-16">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-3">
            Quick start
          </h2>
          <p className="text-muted-foreground max-w-2xl mb-10">
            The homepage is only an overview. The guide is the main reference
            for what to run and in what order.
          </p>
        </ScrollReveal>

        <div className="grid gap-4 md:grid-cols-3">
          {QUICK_START_STEPS.map((step, index) => (
            <ScrollReveal
              key={step.title}
              delay={index * 70}
              className="rounded-xl border border-white/8 bg-gaming-surface/35 p-6"
            >
              <p className="font-mono text-xs text-gaming-cyan mb-3">
                Step {index + 1}
              </p>
              <h3 className="font-heading text-lg font-semibold mb-2">
                {step.title}
              </h3>
              <p className="text-sm text-muted-foreground leading-relaxed">
                {step.description}
              </p>
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export function IncludedSection() {
  return (
    <section id="included" className="py-16">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-3">
            What&apos;s included
          </h2>
          <p className="text-muted-foreground max-w-2xl mb-10">
            The repo is organized into a few main areas so you can find the
            scripts you need without digging through everything.
          </p>
        </ScrollReveal>

        <div className="grid gap-4 md:grid-cols-2">
          {INCLUDED_SECTIONS.map((section, index) => (
            <ScrollReveal
              key={section.title}
              delay={index * 60}
              className="rounded-xl border border-white/8 bg-gaming-surface/25 p-6"
            >
              <h3 className="font-heading text-lg font-semibold mb-2">
                {section.title}
              </h3>
              <p className="text-sm text-muted-foreground leading-relaxed">
                {section.description}
              </p>
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export function FilesSection() {
  return (
    <section className="py-16">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-3">
            Files and scripts
          </h2>
          <p className="text-muted-foreground max-w-2xl mb-10">
            These are the main files to open or run. Start with the guide, then
            use the scripts that match the sections you want.
          </p>
        </ScrollReveal>

        <div className="grid gap-4">
          {FILE_LINKS.map((item, index) => (
            <ScrollReveal
              key={item.path}
              delay={index * 50}
              className="rounded-xl border border-white/8 bg-gaming-surface/25 p-5 sm:p-6"
            >
              <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                <div className="max-w-2xl">
                  <h3 className="font-heading text-lg font-semibold mb-2">
                    {item.title}
                  </h3>
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
          ))}
        </div>
      </div>
    </section>
  );
}

export function TradeoffsSection() {
  return (
    <section className="py-16">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <div className="rounded-2xl border border-white/8 bg-gaming-surface/30 p-7 sm:p-8">
            <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-4">
              Safety and tradeoffs
            </h2>
            <div className="space-y-3 text-sm sm:text-base text-muted-foreground leading-relaxed max-w-3xl">
              <p>
                Some scripts are aggressive and are not the right fit for every
                PC.
              </p>
              <p>
                Many changes have revert support, but not every change is
                perfectly reversible in every case.
              </p>
              <p>
                Read the guide before running everything, especially on laptops,
                work machines, or systems that do more than gaming.
              </p>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
