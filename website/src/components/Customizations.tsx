"use client";

import { Terminal } from "@/components/Terminal";
import { CUSTOMIZATIONS } from "@/lib/constants";
import { ScrollReveal } from "./ScrollReveal";

export function Customizations() {
  return (
    <section className="py-24">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          <ScrollReveal variant="left">
            <Terminal
              lines={[
                {
                  text: ".\\APPLY-EVERYTHING.ps1",
                  color: "text-gaming-green",
                },
                {
                  text: "# Restoring classic right-click menu...",
                  color: "text-muted-foreground",
                },
                {
                  text: "# Cleaning taskbar...",
                  color: "text-muted-foreground",
                },
                {
                  text: "# Enabling dark mode...",
                  color: "text-muted-foreground",
                },
                {
                  text: "# Disabling Bing search...",
                  color: "text-muted-foreground",
                },
                {
                  text: "Done — 8 customizations applied",
                  color: "text-gaming-green",
                },
              ]}
            />
          </ScrollReveal>

          <ScrollReveal variant="right">
            <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-6 text-gaming-magenta">
              Windows cleanup
            </h2>
            <p className="text-muted-foreground mb-6">
              Applied automatically with everything else. No extra steps.
            </p>
            <ul className="space-y-2.5">
              {CUSTOMIZATIONS.map((item) => (
                <li
                  key={item}
                  className="flex items-start gap-2.5 text-sm text-muted-foreground"
                >
                  <span className="text-gaming-cyan mt-0.5 shrink-0">▸</span>
                  {item}
                </li>
              ))}
            </ul>
          </ScrollReveal>
        </div>
      </div>
    </section>
  );
}
