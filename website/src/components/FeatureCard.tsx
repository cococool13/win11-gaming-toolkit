import {
  Zap,
  Gamepad2,
  TerminalSquare,
  Undo2,
  CheckCircle2,
  ShieldCheck,
} from "lucide-react";

const ICONS: Record<string, React.ElementType> = {
  zap: Zap,
  gamepad: Gamepad2,
  terminal: TerminalSquare,
  undo: Undo2,
  check: CheckCircle2,
  shield: ShieldCheck,
};

export function FeatureCard({
  title,
  description,
  icon,
}: {
  title: string;
  description: string;
  icon: string;
}) {
  const Icon = ICONS[icon] || Zap;

  return (
    <div className="group p-6 rounded-xl border border-white/5 bg-gaming-surface/50 hover:border-gaming-cyan/20 hover:shadow-[0_0_30px_rgba(6,182,212,0.08)] transition-all duration-300">
      <div className="w-10 h-10 rounded-lg bg-gaming-cyan/10 flex items-center justify-center mb-4 group-hover:bg-gaming-cyan/20 transition-colors">
        <Icon className="w-5 h-5 text-gaming-cyan" />
      </div>
      <h3 className="font-heading text-lg font-semibold mb-2">{title}</h3>
      <p className="text-sm text-muted-foreground leading-relaxed">
        {description}
      </p>
    </div>
  );
}
