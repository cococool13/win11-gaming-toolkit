export const GITHUB_REPO_URL = "#"; // Replace with actual repo URL
export const GITHUB_RELEASES_URL = "#"; // Replace with actual releases URL

export const HERO_STATS = [
  "10-35% FPS gain",
  "Fully reversible",
  "No .exe files",
  "Open source",
];

export const STEPS = [
  {
    number: 0,
    name: "Prerequisites",
    difficulty: "Easy" as const,
    risk: "None" as const,
    revertible: "N/A",
    description: "VC++ Redistributables and DirectX runtime.",
  },
  {
    number: 1,
    name: "Backup",
    difficulty: "Easy" as const,
    risk: "None" as const,
    revertible: "N/A",
    description: "System restore point and registry backup.",
  },
  {
    number: 2,
    name: "Power Plan",
    difficulty: "Easy" as const,
    risk: "Safe" as const,
    revertible: "Yes",
    description: "Ultimate Performance plan, all cores unparked, no throttling.",
  },
  {
    number: 3,
    name: "Windows Settings",
    difficulty: "Easy" as const,
    risk: "Safe" as const,
    revertible: "Yes",
    description:
      "Disable transparency, background apps, notifications. Enable HAGS.",
  },
  {
    number: 4,
    name: "Services",
    difficulty: "Easy" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description: "Disable telemetry, phone service, geolocation, fax.",
  },
  {
    number: 5,
    name: "Registry Tweaks",
    difficulty: "Medium" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description:
      "Game priority, mouse acceleration off, visual effects, privacy lockdown.",
  },
  {
    number: 6,
    name: "Startup Cleanup",
    difficulty: "Easy" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description: "Disable OneDrive, Teams, Widgets, Cortana, Copilot autostart.",
  },
  {
    number: 7,
    name: "GPU",
    difficulty: "Medium" as const,
    risk: "Safe" as const,
    revertible: "Yes",
    description: "MSI mode for lower interrupt latency.",
  },
  {
    number: 8,
    name: "Network",
    difficulty: "Medium" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description: "Disable Nagle, enable RSS, Cloudflare DNS.",
  },
  {
    number: 9,
    name: "Customization",
    difficulty: "Easy" as const,
    risk: "Safe" as const,
    revertible: "Yes",
    description:
      "Classic right-click menu, clean taskbar, dark mode, disable Bing search.",
  },
  {
    number: 10,
    name: "Debloat",
    difficulty: "Easy" as const,
    risk: "Low" as const,
    revertible: "Partial",
    description: "Remove Clipchamp, Solitaire, Maps, and 20+ other bundled apps.",
  },
] as const;

export type BentoSize = "large" | "small" | "full";

export const FEATURES = [
  {
    title: "One Script",
    description: "APPLY-EVERYTHING.ps1 runs all steps. Takes about 2 minutes.",
    icon: "zap",
    size: "large" as BentoSize,
    glowColor: "green",
  },
  {
    title: "Win11 Cleanup",
    description:
      "Classic right-click menu, clean taskbar, Bing gone, dark mode, no ads.",
    icon: "terminal",
    size: "small" as BentoSize,
    glowColor: "cyan",
  },
  {
    title: "Debloat",
    description: "Remove OneDrive, Teams, Widgets, Copilot, and 20+ apps.",
    icon: "gamepad",
    size: "small" as BentoSize,
    glowColor: "magenta",
  },
  {
    title: "Reversible",
    description: "REVERT-EVERYTHING.ps1 undoes all changes.",
    icon: "undo",
    size: "small" as BentoSize,
    glowColor: "cyan",
  },
  {
    title: "Health Check",
    description: "verify-tweaks.ps1 shows what's applied and what's missing.",
    icon: "check",
    size: "small" as BentoSize,
    glowColor: "cyan",
  },
  {
    title: "No Executables",
    description:
      "PowerShell and batch scripts only. Read the source before you run it.",
    icon: "shield",
    size: "full" as BentoSize,
    glowColor: "cyan",
  },
] as const;

export const PERFORMANCE_DATA = [
  {
    category: "Power Plan + Services",
    gain: "2-5%",
    risk: "Safe",
    group: "windows",
  },
  {
    category: "Registry Tweaks",
    gain: "1-3%",
    risk: "Low",
    group: "windows",
  },
  {
    category: "Timer Resolution Service",
    gain: "1-3%",
    risk: "Low",
    group: "windows",
  },
  {
    category: "GPU MSI Mode",
    gain: "2-10%",
    risk: "Safe",
    group: "windows",
  },
  {
    category: "Network Optimization",
    gain: "Lower ping",
    risk: "Low",
    group: "windows",
  },
  {
    category: "VBS/HVCI Disabled",
    gain: "5-25%",
    risk: "Moderate",
    group: "windows",
  },
  {
    category: "XMP/DOCP (RAM speed)",
    gain: "10-30%",
    risk: "Safe",
    group: "bios",
  },
  {
    category: "Resizable BAR",
    gain: "5-15%",
    risk: "Safe",
    group: "bios",
  },
] as const;

export const CUSTOMIZATIONS = [
  "Classic right-click menu (Win10 style)",
  "Clean taskbar — no Search, Widgets, or Chat",
  "Bing and web results removed from Start search",
  "Dark mode enabled",
  "Lock screen ads and tips disabled",
  "Start Menu suggestions removed",
  "This PC shown on desktop",
  "OneDrive, Teams, Widgets, Cortana, Copilot disabled",
] as const;

export const FAQ_ITEMS = [
  {
    question: "What gives the biggest FPS gain?",
    answer:
      "VBS/HVCI disable gives 5-25%. XMP in BIOS gives 10-30% in CPU-bound games. Both are optional and separate from the main script.",
  },
  {
    question: "Is this safe?",
    answer:
      "Every tweak is reversible. Run REVERT-EVERYTHING.ps1 to undo. VBS is the only real trade-off and it's optional.",
  },
  {
    question: "Do I need to run all steps?",
    answer:
      "No. APPLY-EVERYTHING.ps1 handles everything automatically. Or use launcher.ps1 to pick individual steps.",
  },
  {
    question: "How do I undo?",
    answer:
      "Run REVERT-EVERYTHING.ps1 as Administrator. Or restore from the system restore point created in Step 1.",
  },
  {
    question: "Will this break anti-cheat?",
    answer:
      "The main script is fine. VBS disable may conflict with Vanguard or FACEIT — re-enable VBS for those games.",
  },
  {
    question: "Why no .exe files?",
    answer:
      "Scripts are readable. You can check every line before running. Downloads come from official sources.",
  },
] as const;
