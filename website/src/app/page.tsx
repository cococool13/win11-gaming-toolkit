import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { StepsTimeline } from "@/components/StepsTimeline";
import { BentoFeatures } from "@/components/BentoFeatures";
import { Customizations } from "@/components/Customizations";
import { PerformanceTable } from "@/components/PerformanceTable";
import { DownloadCta } from "@/components/DownloadCta";
import { FaqAccordion } from "@/components/FaqAccordion";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <BentoFeatures />
        <StepsTimeline />
        <Customizations />
        <PerformanceTable />
        <DownloadCta />
        <FaqAccordion />
      </main>
      <Footer />
    </>
  );
}
