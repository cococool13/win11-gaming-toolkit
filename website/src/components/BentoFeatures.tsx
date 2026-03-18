"use client";

import {
  Zap,
  Gamepad2,
  TerminalSquare,
  Undo2,
  CheckCircle2,
  ShieldCheck,
} from "lucide-react";
import { FEATURES } from "@/lib/constants";
import { ScrollReveal } from "./ScrollReveal";

const ICONS: Record<string, React.ElementType> = {
  zap: Zap,
  gamepad: Gamepad2,
  terminal: TerminalSquare,
  undo: Undo2,
  check: CheckCircle2,
  shield: ShieldCheck,
};

const GLOW: Record<string, string> = {
  green: "hover:border-gaming-green/25 hover:shadow-[0_0_24px_rgba(34,197,94,0.08)]",
  magenta: "hover:border-gaming-magenta/25 hover:shadow-[0_0_24px_rgba(217,70,239,0.08)]",
  cyan: "hover:border-gaming-cyan/20 hover:shadow-[0_0_24px_rgba(6,182,212,0.06)]",
};

const ICON_BG: Record<string, string> = {
  green: "bg-gaming-green/10 group-hover:bg-gaming-green/20",
  magenta: "bg-gaming-magenta/10 group-hover:bg-gaming-magenta/20",
  cyan: "bg-gaming-cyan/10 group-hover:bg-gaming-cyan/20",
};

const ICON_COLOR: Record<string, string> = {
  green: "text-gaming-green",
  magenta: "text-gaming-magenta",
  cyan: "text-gaming-cyan",
};

export function BentoFeatures() {
  return (
    <section id="features" className="py-16">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-10">
            What it does
          </h2>
        </ScrollReveal>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {FEATURES.map((feature, i) => {
            const Icon = ICONS[feature.icon] || Zap;
            const span =
              feature.size === "large"
                ? "sm:col-span-2"
                : feature.size === "full"
                ? "sm:col-span-2 lg:col-span-3"
                : "";

            return (
              <ScrollReveal
                key={feature.title}
                delay={i * 60}
                variant={i % 2 === 0 ? "up" : "blur"}
                className={span}
              >
                <div
                  className={`group relative p-6 rounded-xl border border-white/5 bg-gaming-surface/40 transition-all duration-300 h-full ${GLOW[feature.glowColor]}`}
                >
                  <div
                    className={`w-9 h-9 rounded-lg flex items-center justify-center mb-4 transition-colors ${ICON_BG[feature.glowColor]}`}
                  >
                    <Icon
                      className={`w-4.5 h-4.5 ${ICON_COLOR[feature.glowColor]}`}
                    />
                  </div>
                  <h3 className="font-heading text-base font-semibold mb-1.5">
                    {feature.title}
                  </h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    {feature.description}
                  </p>
                </div>
              </ScrollReveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}
