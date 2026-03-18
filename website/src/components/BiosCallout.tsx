import { ScrollReveal } from "./ScrollReveal";

export function BiosCallout() {
  return (
    <section className="py-16 bg-gaming-surface/30">
      <div className="max-w-4xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <div className="rounded-xl border border-gaming-yellow/20 bg-gaming-yellow/5 p-8 sm:p-10">
            <div className="flex flex-col sm:flex-row gap-6 items-start">
              <div className="text-4xl shrink-0">&#9889;</div>
              <div>
                <h3 className="font-heading text-xl font-bold mb-2">
                  Before You Run a Single Script — Check Your BIOS
                </h3>
                <p className="text-muted-foreground mb-4">
                  The biggest free performance gains come from your BIOS
                  settings, not Windows tweaks. Most PCs ship with these
                  disabled by default.
                </p>
                <div className="grid sm:grid-cols-2 gap-4">
                  <div className="rounded-lg bg-gaming-bg/50 p-4">
                    <div className="font-mono text-2xl font-bold text-gaming-green mb-1">
                      10-30%
                    </div>
                    <div className="text-sm text-muted-foreground">
                      <strong className="text-foreground">XMP/DOCP/EXPO</strong>{" "}
                      — Your RAM is probably running at half speed. Enable XMP
                      in BIOS to unlock its rated speed.
                    </div>
                  </div>
                  <div className="rounded-lg bg-gaming-bg/50 p-4">
                    <div className="font-mono text-2xl font-bold text-gaming-green mb-1">
                      5-15%
                    </div>
                    <div className="text-sm text-muted-foreground">
                      <strong className="text-foreground">Resizable BAR</strong>{" "}
                      — Lets your CPU access the full GPU VRAM at once. Free FPS
                      in supported games.
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
