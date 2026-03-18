export const GITHUB_REPO_URL = "#"; // Replace with actual repo URL
export const GITHUB_RELEASES_URL = "#"; // Replace with actual releases URL

export const STEPS = [
  {
    number: 0,
    name: "Install Gaming Prerequisites",
    difficulty: "Easy" as const,
    risk: "None" as const,
    revertible: "N/A",
    description:
      "Downloads and installs all Visual C++ Redistributables (2005-2022) and DirectX runtime. Prevents 'DLL not found' errors.",
  },
  {
    number: 1,
    name: "Backup & Restore Point",
    difficulty: "Easy" as const,
    risk: "None" as const,
    revertible: "N/A",
    description:
      "Creates a system restore point and registry backup before any changes. Your safety net.",
  },
  {
    number: 2,
    name: "Power Plan",
    difficulty: "Easy" as const,
    risk: "Safe" as const,
    revertible: "Yes",
    description:
      "Activates the hidden Ultimate Performance power plan. Keeps CPU at max clock speed and eliminates micro-stutters.",
  },
  {
    number: 3,
    name: "Windows Settings",
    difficulty: "Easy" as const,
    risk: "Safe" as const,
    revertible: "Yes (manual)",
    description:
      "Manual UI tweaks via guided checklist. Disable animations, transparency, background apps, and Game Bar.",
  },
  {
    number: 4,
    name: "Disable Unnecessary Services",
    difficulty: "Easy" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description:
      "Stops telemetry, phone service, geolocation, print spooler, and other resource-draining background services.",
  },
  {
    number: 5,
    name: "Registry Tweaks",
    difficulty: "Medium" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description:
      "20+ tweaks: visual effects, game priority, disable power throttling, privacy/telemetry, explorer optimizations.",
  },
  {
    number: 6,
    name: "GPU Optimization",
    difficulty: "Medium" as const,
    risk: "Safe" as const,
    revertible: "Yes",
    description:
      "Enables MSI mode for your GPU (NVIDIA/AMD/Intel) for lower interrupt latency. Includes driver guides.",
  },
  {
    number: 7,
    name: "Network Optimization",
    difficulty: "Medium" as const,
    risk: "Low" as const,
    revertible: "Yes",
    description:
      "Disables Nagle's Algorithm, enables RSS, configures DNS (Cloudflare/Google). Reduces online gaming latency.",
  },
  {
    number: 8,
    name: "Security vs Performance",
    difficulty: "Medium" as const,
    risk: "Moderate" as const,
    revertible: "Yes",
    description:
      "Disables VBS/HVCI for 5-25% FPS gain. Honest security trade-off explained in detail. Your choice.",
  },
  {
    number: 9,
    name: "Cleanup & Debloat",
    difficulty: "Easy" as const,
    risk: "Low" as const,
    revertible: "Partial",
    description:
      "Removes Windows bloatware, clears temp files and caches. Includes Chris Titus WinUtil launcher.",
  },
  {
    number: 10,
    name: "Verify & Benchmark",
    difficulty: "Easy" as const,
    risk: "None" as const,
    revertible: "N/A",
    description:
      "Automated health check with color-coded report. Verifies every tweak is applied and shows optimization score.",
  },
] as const;

export const FEATURES = [
  {
    title: "One-Click Apply",
    description:
      "Run APPLY-EVERYTHING.ps1 as Administrator. All safe tweaks applied in under 2 minutes.",
    icon: "zap",
  },
  {
    title: "Gaming Mode",
    description:
      "Pre-session optimizer closes browsers, OneDrive, and background apps. Silences notifications. Restores on reboot.",
    icon: "gamepad",
  },
  {
    title: "Interactive Launcher",
    description:
      "24+ options in a color-coded terminal menu. Pick and choose exactly which optimizations you want.",
    icon: "terminal",
  },
  {
    title: "100% Reversible",
    description:
      "Every tweak has a revert script. REVERT-EVERYTHING.ps1 undoes all changes with one click.",
    icon: "undo",
  },
  {
    title: "Verification Report",
    description:
      "Run verify-tweaks.ps1 for a color-coded health check. See exactly what's applied and your optimization score.",
    icon: "check",
  },
  {
    title: "Zero Executables",
    description:
      "Pure PowerShell and batch scripts you can read and audit. No compiled binaries. No hidden code.",
    icon: "shield",
  },
] as const;

export const TRUST_STATS = [
  { value: "10-35%", label: "FPS Gain" },
  { value: "24+", label: "Options" },
  { value: "100%", label: "Reversible" },
  { value: "0", label: "Executables" },
  { value: "Open", label: "Source" },
] as const;

export const PERFORMANCE_DATA = [
  {
    category: "Power Plan + Services",
    gain: "2-5%",
    risk: "Safe",
  },
  {
    category: "Registry Tweaks",
    gain: "1-3%",
    risk: "Low",
  },
  {
    category: "Timer Resolution Service",
    gain: "1-3%",
    risk: "Low",
  },
  {
    category: "GPU MSI Mode + Optimization",
    gain: "2-10%",
    risk: "Safe",
  },
  {
    category: "Network Optimization",
    gain: "Lower ping",
    risk: "Low",
  },
  {
    category: "VBS/HVCI Disabled",
    gain: "5-25%",
    risk: "Moderate",
  },
  {
    category: "BIOS: XMP/DOCP",
    gain: "10-30%",
    risk: "Safe",
  },
  {
    category: "BIOS: Resizable BAR",
    gain: "5-15%",
    risk: "Safe",
  },
] as const;

export const GAMING_MODE_FEATURES = [
  "Closes resource-hungry apps (browsers, OneDrive, Teams)",
  "Silences all Windows notifications",
  "Clears standby RAM for more available memory",
  "Pauses Windows Update during your session",
  "Sets game process priority to High",
  "Everything restores on reboot or gaming-mode-off.ps1",
] as const;

export const FAQ_ITEMS = [
  {
    question: "What's the single biggest FPS gain?",
    answer:
      "Disabling VBS/HVCI (Step 8). It's 5-25% but has a security trade-off. For a risk-free boost, enabling XMP in your BIOS gives 10-30% in CPU-bound games.",
  },
  {
    question: "Is this safe?",
    answer:
      "Every tweak is reversible. We removed harmful tweaks from common guides (disabling BITS, SysMain, Prefetch). The only real trade-off is Step 8 (VBS), which is clearly documented and optional.",
  },
  {
    question: "What if I just want to run one thing?",
    answer:
      "Run APPLY-EVERYTHING.ps1 as Administrator. It applies all safe tweaks at once and skips the VBS trade-off (that's a manual choice).",
  },
  {
    question: "Do I need to run all steps?",
    answer:
      "No. Each step is independent. Steps 2 (Power Plan), 5 (Registry), and 8 (VBS) give the biggest gains for the least effort.",
  },
  {
    question: "I have a laptop. Should I do all of this?",
    answer:
      "Skip the advanced power plan tuning on battery. Everything else is fine. The toolkit detects your system and adjusts accordingly.",
  },
  {
    question: "How do I undo everything?",
    answer:
      "Run REVERT-EVERYTHING.ps1 as Administrator — it undoes everything. Or use the System Restore point created in Step 1.",
  },
  {
    question: "Why don't you bundle any .exe tools?",
    answer:
      "Bundled executables go stale, can be tampered with, and create licensing issues. We link to official download pages so you always get the latest verified version.",
  },
  {
    question: "Will this break anti-cheat software?",
    answer:
      "Most tweaks are fine. Disabling VBS (Step 8) may conflict with some anti-cheat systems like Vanguard or FACEIT. Re-enable VBS for those games.",
  },
  {
    question: "How do I verify my tweaks are still applied?",
    answer:
      "Run verify-tweaks.ps1 as Administrator. It checks every tweak and gives you a color-coded health report with an optimization score.",
  },
] as const;
