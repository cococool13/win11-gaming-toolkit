import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { TrustBar } from "@/components/TrustBar";
import { StepsTimeline } from "@/components/StepsTimeline";
import { FeaturesGrid } from "@/components/FeaturesGrid";
import { GamingMode } from "@/components/GamingMode";
import { BiosCallout } from "@/components/BiosCallout";
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
        <TrustBar />
        <StepsTimeline />
        <FeaturesGrid />
        <GamingMode />
        <BiosCallout />
        <PerformanceTable />
        <DownloadCta />
        <FaqAccordion />
      </main>
      <Footer />
    </>
  );
}
