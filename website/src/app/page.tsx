import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { DownloadCta } from "@/components/DownloadCta";
import { FaqAccordion } from "@/components/FaqAccordion";
import { Footer } from "@/components/Footer";
import {
  FilesSection,
  IncludedSection,
  QuickStartSection,
  TradeoffsSection,
} from "@/components/HomeSections";

export default function Home() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <QuickStartSection />
        <IncludedSection />
        <FilesSection />
        <TradeoffsSection />
        <DownloadCta />
        <FaqAccordion />
      </main>
      <Footer />
    </>
  );
}
