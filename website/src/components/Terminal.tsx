"use client";

export function Terminal({
  lines,
  typing = false,
}: {
  lines: { text: string; color?: string }[];
  typing?: boolean;
}) {
  return (
    <div className="rounded-lg border border-white/10 bg-gaming-bg overflow-hidden font-mono text-sm">
      <div className="flex items-center gap-1.5 px-4 py-2.5 bg-white/5 border-b border-white/10">
        <div className="w-3 h-3 rounded-full bg-gaming-red/80" />
        <div className="w-3 h-3 rounded-full bg-gaming-yellow/80" />
        <div className="w-3 h-3 rounded-full bg-gaming-green/80" />
        <span className="ml-2 text-xs text-muted-foreground">
          PowerShell (Admin)
        </span>
      </div>
      <div className="p-4 space-y-1">
        {lines.map((line, i) => (
          <div key={i} className="flex">
            <span className="text-gaming-cyan mr-2 select-none">PS&gt;</span>
            <span
              className={`${
                typing && i === lines.length - 1 ? "typing-animation" : ""
              } ${line.color || "text-foreground"}`}
            >
              {line.text}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
