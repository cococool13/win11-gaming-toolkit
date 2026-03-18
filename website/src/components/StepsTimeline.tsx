import { STEPS } from "@/lib/constants";
import { StepCard } from "./StepCard";
import { ScrollReveal } from "./ScrollReveal";

export function StepsTimeline() {
  return (
    <section id="steps" className="py-20">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold text-center mb-4">
            10-Step <span className="text-gaming-cyan">Optimization</span>{" "}
            System
          </h2>
          <p className="text-center text-muted-foreground mb-12 max-w-lg mx-auto">
            Follow each step in order, or jump to whichever interests you. Every
            step is independent and reversible.
          </p>
        </ScrollReveal>

        <div>
          {STEPS.map((step, i) => (
            <ScrollReveal key={step.number} delay={i * 50}>
              <StepCard
                number={step.number}
                name={step.name}
                difficulty={step.difficulty}
                risk={step.risk}
                description={step.description}
              />
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}
