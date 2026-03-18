import { TRUST_STATS } from "@/lib/constants";
import { ScrollReveal } from "./ScrollReveal";

export function TrustBar() {
  return (
    <section className="py-12 border-y border-white/5 bg-gaming-surface/50">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-8">
            {TRUST_STATS.map((stat) => (
              <div key={stat.label} className="text-center">
                <div className="font-mono text-3xl font-bold text-gaming-cyan mb-1">
                  {stat.value}
                </div>
                <div className="text-sm text-muted-foreground">
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
