import { FEATURES } from "@/lib/constants";
import { FeatureCard } from "./FeatureCard";
import { ScrollReveal } from "./ScrollReveal";

export function FeaturesGrid() {
  return (
    <section id="features" className="py-20 bg-gaming-surface/30">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold text-center mb-4">
            Built for <span className="text-gaming-cyan">Gamers</span>
          </h2>
          <p className="text-center text-muted-foreground mb-12 max-w-lg mx-auto">
            Everything you need to squeeze maximum performance out of Windows
            11, with zero risk.
          </p>
        </ScrollReveal>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {FEATURES.map((feature, i) => (
            <ScrollReveal key={feature.title} delay={i * 80}>
              <FeatureCard
                title={feature.title}
                description={feature.description}
                icon={feature.icon}
              />
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}
