import { STEPS } from "@/lib/constants";
import { StepCard } from "./StepCard";
import { ScrollReveal } from "./ScrollReveal";

export function StepsTimeline() {
  return (
    <section id="steps" className="py-24">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-10">
            Steps
          </h2>
        </ScrollReveal>

        <div>
          {STEPS.map((step, i) => (
            <ScrollReveal key={step.number} delay={i * 40}>
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
