import { PERFORMANCE_DATA } from "@/lib/constants";
import { Badge } from "@/components/ui/badge";
import { ScrollReveal } from "./ScrollReveal";

const RISK_COLORS: Record<string, string> = {
  Safe: "bg-gaming-green/10 text-gaming-green border-gaming-green/20",
  Low: "bg-gaming-yellow/10 text-gaming-yellow border-gaming-yellow/20",
  Moderate: "bg-amber-500/10 text-amber-400 border-amber-500/20",
};

export function PerformanceTable() {
  const windowsRows = PERFORMANCE_DATA.filter((r) => r.group === "windows");
  const biosRows = PERFORMANCE_DATA.filter((r) => r.group === "bios");

  return (
    <section className="py-20">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <ScrollReveal>
          <h2 className="font-heading text-3xl sm:text-4xl font-bold mb-10">
            FPS gains
          </h2>
        </ScrollReveal>

        <ScrollReveal variant="up" delay={100}>
          <div className="rounded-xl border border-white/10 overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gaming-surface border-b border-white/10">
                  <th className="text-left px-4 sm:px-6 py-3 font-heading font-semibold text-muted-foreground">
                    Optimization
                  </th>
                  <th className="text-right px-4 sm:px-6 py-3 font-heading font-semibold text-muted-foreground">
                    FPS Gain
                  </th>
                  <th className="text-right px-4 sm:px-6 py-3 font-heading font-semibold text-muted-foreground hidden sm:table-cell">
                    Risk
                  </th>
                </tr>
              </thead>
              <tbody>
                {windowsRows.map((row) => (
                  <tr
                    key={row.category}
                    className="border-b border-white/5 hover:bg-white/[0.02] transition-colors"
                  >
                    <td className="px-4 sm:px-6 py-3">{row.category}</td>
                    <td className="px-4 sm:px-6 py-3 text-right font-mono font-semibold text-gaming-green">
                      {row.gain}
                    </td>
                    <td className="px-4 sm:px-6 py-3 text-right hidden sm:table-cell">
                      <Badge
                        variant="outline"
                        className={RISK_COLORS[row.risk]}
                      >
                        {row.risk}
                      </Badge>
                    </td>
                  </tr>
                ))}

                {/* BIOS group header */}
                <tr className="border-b border-white/5">
                  <td
                    colSpan={3}
                    className="px-4 sm:px-6 py-2 text-xs font-mono text-gaming-yellow/70 uppercase tracking-wider bg-gaming-yellow/[0.03]"
                  >
                    BIOS — not scripted, do these manually
                  </td>
                </tr>

                {biosRows.map((row) => (
                  <tr
                    key={row.category}
                    className="border-b border-white/5 hover:bg-white/[0.02] transition-colors border-l-2 border-l-gaming-yellow/30"
                  >
                    <td className="px-4 sm:px-6 py-3">{row.category}</td>
                    <td className="px-4 sm:px-6 py-3 text-right font-mono font-semibold text-gaming-green">
                      {row.gain}
                    </td>
                    <td className="px-4 sm:px-6 py-3 text-right hidden sm:table-cell">
                      <Badge
                        variant="outline"
                        className={RISK_COLORS[row.risk]}
                      >
                        {row.risk}
                      </Badge>
                    </td>
                  </tr>
                ))}

                <tr className="bg-gaming-green/5">
                  <td className="px-4 sm:px-6 py-3 font-heading font-bold text-gaming-green">
                    Total Combined
                  </td>
                  <td className="px-4 sm:px-6 py-3 text-right font-mono font-bold text-gaming-green text-lg">
                    10-35%+
                  </td>
                  <td className="px-4 sm:px-6 py-3 hidden sm:table-cell" />
                </tr>
              </tbody>
            </table>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
