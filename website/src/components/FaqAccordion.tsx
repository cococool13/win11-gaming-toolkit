"use client";

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { FAQ_ITEMS } from "@/lib/constants";
import { ScrollReveal } from "./ScrollReveal";

export function FaqAccordion() {
  return (
    <section id="faq" className="py-16">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-10">
            Questions
          </h2>
        </ScrollReveal>

        <ScrollReveal variant="up" delay={80}>
          <Accordion className="space-y-2">
            {FAQ_ITEMS.map((item, i) => (
              <AccordionItem
                key={i}
                className="border border-white/5 rounded-lg px-6 bg-gaming-surface/30 data-[open]:border-gaming-cyan/20"
              >
                <AccordionTrigger className="text-left font-heading font-semibold hover:text-gaming-cyan hover:no-underline transition-colors py-4 text-[0.95rem]">
                  {item.question}
                </AccordionTrigger>
                <AccordionContent className="text-muted-foreground pb-4 text-sm leading-relaxed">
                  {item.answer}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </ScrollReveal>
      </div>
    </section>
  );
}
