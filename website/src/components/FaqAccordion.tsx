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
    <section id="faq" className="py-20">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold text-center mb-4">
            Frequently Asked{" "}
            <span className="text-gaming-cyan">Questions</span>
          </h2>
          <p className="text-center text-muted-foreground mb-12">
            Everything you need to know before getting started.
          </p>
        </ScrollReveal>

        <ScrollReveal>
          <Accordion className="space-y-3">
            {FAQ_ITEMS.map((item, i) => (
              <AccordionItem
                key={i}
                className="border border-white/5 rounded-lg px-6 bg-gaming-surface/30 data-[open]:border-gaming-cyan/20"
              >
                <AccordionTrigger className="text-left font-heading font-semibold hover:text-gaming-cyan hover:no-underline transition-colors py-4">
                  {item.question}
                </AccordionTrigger>
                <AccordionContent className="text-muted-foreground pb-4">
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
