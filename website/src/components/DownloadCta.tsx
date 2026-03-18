"use client";

import { buttonVariants } from "@/components/ui/button";
import { Terminal } from "./Terminal";
import { ScrollReveal } from "./ScrollReveal";
import { GITHUB_RELEASES_URL, GITHUB_REPO_URL } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function DownloadCta() {
  return (
    <section
      id="download"
      className="py-20 bg-gaming-surface/30 relative overflow-hidden"
    >
      {/* Glow */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-gaming-cyan/5 rounded-full blur-[128px] pointer-events-none" />

      <div className="max-w-4xl mx-auto px-4 sm:px-6 relative">
        <ScrollReveal>
          <div className="text-center mb-12">
            <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-4">
              Ready to{" "}
              <span className="text-gaming-green">Boost Your FPS</span>?
            </h2>
            <p className="text-muted-foreground max-w-lg mx-auto">
              Download the toolkit, extract, and run as Administrator. Three
              steps to a faster PC.
            </p>
          </div>
        </ScrollReveal>

        <ScrollReveal delay={100}>
          {/* 3-step quick start */}
          <div className="grid sm:grid-cols-3 gap-6 mb-12">
            {[
              {
                step: "1",
                title: "Download",
                desc: "Get the latest release from GitHub",
              },
              {
                step: "2",
                title: "Extract",
                desc: "Unzip to any folder on your PC",
              },
              {
                step: "3",
                title: "Run as Admin",
                desc: "Right-click > Run as Administrator",
              },
            ].map((item) => (
              <div key={item.step} className="text-center">
                <div className="w-12 h-12 rounded-full bg-gaming-cyan/10 border border-gaming-cyan/30 flex items-center justify-center font-mono text-xl font-bold text-gaming-cyan mx-auto mb-3">
                  {item.step}
                </div>
                <h3 className="font-heading font-semibold mb-1">
                  {item.title}
                </h3>
                <p className="text-sm text-muted-foreground">{item.desc}</p>
              </div>
            ))}
          </div>
        </ScrollReveal>

        <ScrollReveal delay={200}>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-8">
            <a
              href={GITHUB_RELEASES_URL}
              className={cn(
                buttonVariants({ size: "lg" }),
                "bg-gaming-green hover:bg-gaming-green/90 text-black font-semibold px-8"
              )}
            >
              Download Latest Release
            </a>
            <a
              href={GITHUB_REPO_URL}
              target="_blank"
              rel="noopener noreferrer"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "border-gaming-cyan/30 text-gaming-cyan hover:bg-gaming-cyan/10"
              )}
            >
              View Source Code
            </a>
          </div>
        </ScrollReveal>

        <ScrollReveal delay={300}>
          <div className="max-w-lg mx-auto">
            <p className="text-xs text-center text-muted-foreground mb-3">
              Or clone with git:
            </p>
            <Terminal
              lines={[
                {
                  text: "git clone <repo-url>",
                  color: "text-gaming-cyan",
                },
              ]}
            />
          </div>
        </ScrollReveal>

        <ScrollReveal delay={350}>
          <p className="text-center text-xs text-muted-foreground mt-8">
            Every script is readable. No compiled binaries. Verify before you
            run.
          </p>
        </ScrollReveal>
      </div>
    </section>
  );
}
