import { Badge } from "@/components/ui/badge";

type Difficulty = "Easy" | "Medium";
type Risk = "None" | "Safe" | "Low" | "Moderate";

const RISK_COLORS: Record<Risk, string> = {
  None: "bg-gaming-green/10 text-gaming-green border-gaming-green/20",
  Safe: "bg-gaming-green/10 text-gaming-green border-gaming-green/20",
  Low: "bg-gaming-yellow/10 text-gaming-yellow border-gaming-yellow/20",
  Moderate: "bg-amber-500/10 text-amber-400 border-amber-500/20",
};

const DIFFICULTY_COLORS: Record<Difficulty, string> = {
  Easy: "bg-gaming-cyan/10 text-gaming-cyan border-gaming-cyan/20",
  Medium: "bg-gaming-magenta/10 text-gaming-magenta border-gaming-magenta/20",
};

export function StepCard({
  number,
  name,
  difficulty,
  risk,
  description,
}: {
  number: number;
  name: string;
  difficulty: Difficulty;
  risk: Risk;
  description: string;
}) {
  return (
    <div className="flex gap-4 sm:gap-6">
      {/* Timeline line + number */}
      <div className="flex flex-col items-center">
        <div className="w-10 h-10 rounded-full bg-gaming-cyan/10 border border-gaming-cyan/30 flex items-center justify-center font-mono text-sm font-bold text-gaming-cyan shrink-0">
          {number}
        </div>
        <div className="w-px flex-1 bg-white/10 mt-2" />
      </div>

      {/* Content */}
      <div className="pb-8">
        <h3 className="font-heading text-lg font-semibold mb-1">{name}</h3>
        <div className="flex gap-2 mb-2">
          <Badge variant="outline" className={DIFFICULTY_COLORS[difficulty]}>
            {difficulty}
          </Badge>
          <Badge variant="outline" className={RISK_COLORS[risk]}>
            {risk} risk
          </Badge>
        </div>
        <p className="text-sm text-muted-foreground leading-relaxed">
          {description}
        </p>
      </div>
    </div>
  );
}
