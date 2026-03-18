export const GITHUB_REPO_URL = "https://github.com/cococool13/TweakEazy";
export const GITHUB_RELEASES_URL =
  "https://github.com/cococool13/TweakEazy/releases";

function repoFile(path: string) {
  return GITHUB_REPO_URL ? `${GITHUB_REPO_URL}/blob/main/${path}` : "";
}

export const QUICK_START_STEPS = [
  {
    title: "Read the guide",
    description:
      "Start with the guide so you know which scripts are relevant to your PC and what each step changes.",
  },
  {
    title: "Create a backup",
    description:
      "Make a restore point and back up the registry before changing anything.",
  },
  {
    title: "Run the scripts you want",
    description:
      "Use the launcher or run individual scripts based on the sections you actually want to apply.",
  },
] as const;

export const INCLUDED_SECTIONS = [
  {
    title: "Backup and restore point",
    description: "Scripts for restore points, registry backups, and revert paths.",
  },
  {
    title: "Power and Windows settings",
    description:
      "Power plan changes and common Windows settings used in the guide.",
  },
  {
    title: "Services and registry tweaks",
    description:
      "Service changes, registry edits, and startup cleanup steps.",
  },
  {
    title: "GPU and network tweaks",
    description:
      "GPU-related scripts, DDU helpers, and adapter-aware network changes.",
  },
  {
    title: "Revert and verify tools",
    description:
      "Scripts for undoing changes and checking which tweaks are currently applied.",
  },
] as const;

export const FILE_LINKS = [
  {
    title: "Main guide",
    path: "GUIDE.md",
    href: repoFile("GUIDE.md"),
    instruction:
      "Read this first. It explains the sections, order, and tradeoffs before you run anything.",
  },
  {
    title: "Launcher",
    path: "launcher.ps1",
    href: repoFile("launcher.ps1"),
    instruction:
      "Use this if you want a menu for running individual parts of the guide instead of opening folders manually.",
  },
  {
    title: "Apply everything",
    path: "APPLY-EVERYTHING.ps1",
    href: repoFile("APPLY-EVERYTHING.ps1"),
    instruction:
      "Run this only after reading the guide. It applies the full scripted pass and includes higher-tradeoff changes.",
  },
  {
    title: "Revert everything",
    path: "REVERT-EVERYTHING.ps1",
    href: repoFile("REVERT-EVERYTHING.ps1"),
    instruction:
      "Use this to undo the tracked full-apply path when you want to restore prior settings.",
  },
  {
    title: "Verification",
    path: "10 verify/verify-tweaks.ps1",
    href: repoFile("10%20verify/verify-tweaks.ps1"),
    instruction:
      "Run this after making changes to check which tweaks are currently applied and which ones drifted.",
  },
  {
    title: "BIOS checklist",
    path: "BIOS-CHECKLIST.md",
    href: repoFile("BIOS-CHECKLIST.md"),
    instruction:
      "Read this separately for manual BIOS items like XMP, ReBAR, and other non-script changes.",
  },
] as const;

export const FAQ_ITEMS = [
  {
    question: "Do I need to run every step?",
    answer:
      "No. The guide is organized so you can read the sections and choose the scripts that fit your system and goals.",
  },
  {
    question: "How do I undo changes?",
    answer:
      "Use REVERT-EVERYTHING.ps1 for the tracked full revert path, or the individual revert scripts for specific areas.",
  },
  {
    question: "Is this safe for laptops?",
    answer:
      "Some steps work on laptops, but not every tweak is a good fit for every machine. Read the tradeoffs before running everything.",
  },
  {
    question: "What should I read before running everything?",
    answer:
      "Read the main guide first, then the BIOS checklist and any section README that applies to the scripts you plan to run.",
  },
  {
    question: "What is DDU for?",
    answer:
      "DDU is used for clean GPU driver removal before reinstalling drivers. The repo includes helpers for staging and launching that workflow.",
  },
] as const;
