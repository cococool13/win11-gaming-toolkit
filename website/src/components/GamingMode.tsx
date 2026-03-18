import { GAMING_MODE_FEATURES } from "@/lib/constants";
import { Terminal } from "./Terminal";
import { ScrollReveal } from "./ScrollReveal";

export function GamingMode() {
  return (
    <section className="py-20 relative overflow-hidden">
      {/* Magenta glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-gaming-magenta/5 rounded-full blur-[128px] pointer-events-none" />

      <div className="max-w-6xl mx-auto px-4 sm:px-6 relative">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <ScrollReveal>
            <div>
              <div className="inline-block px-3 py-1 rounded-full text-xs font-mono bg-gaming-magenta/10 text-gaming-magenta border border-gaming-magenta/20 mb-4">
                PRE-SESSION OPTIMIZER
              </div>
              <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-4">
                <span className="text-gaming-magenta">Gaming Mode</span>{" "}
                — One Click Before You Play
              </h2>
              <p className="text-muted-foreground mb-6">
                Close background apps, silence notifications, and free up system
                resources. Everything restores automatically when you&apos;re
                done.
              </p>
              <ul className="space-y-3">
                {GAMING_MODE_FEATURES.map((feature) => (
                  <li
                    key={feature}
                    className="flex items-start gap-2 text-sm text-muted-foreground"
                  >
                    <span className="text-gaming-magenta mt-0.5">&#10003;</span>
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
          </ScrollReveal>

          <ScrollReveal delay={150}>
            <Terminal
              lines={[
                {
                  text: ".\\gaming-mode.ps1",
                  color: "text-gaming-magenta",
                },
                {
                  text: "# Closing browsers, OneDrive, Teams...",
                  color: "text-muted-foreground",
                },
                {
                  text: "# Notifications silenced",
                  color: "text-muted-foreground",
                },
                {
                  text: "# RAM cleared. Gaming Mode ACTIVE",
                  color: "text-gaming-green",
                },
              ]}
            />
          </ScrollReveal>
        </div>
      </div>
    </section>
  );
}
