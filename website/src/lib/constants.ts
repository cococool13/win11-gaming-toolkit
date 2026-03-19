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
      "Start with GUIDE.md so you understand the phases, risks, and rollback path before you change anything.",
  },
  {
    title: "Launch the menu",
    description:
      "Use launcher.ps1 as the main entrypoint. It groups the toolkit into setup, optimize, GPU and network, and safety flows.",
  },
  {
    title: "Verify after changes",
    description:
      "Run the verification report after tuning so you can see what is applied, preexisting, unsupported, or drifted.",
  },
] as const;

export const INCLUDED_SECTIONS = [
  {
    title: "Setup",
    description:
      "Restore points, registry backup, and prerequisite installers for a clean starting point.",
  },
  {
    title: "Optimize",
    description:
      "Power, services, registry, cleanup, and optional security trade-off phases.",
  },
  {
    title: "GPU and network",
    description:
      "MSI mode, DDU-backed driver workflows, and adapter-aware network tuning.",
  },
  {
    title: "Safety and verify",
    description:
      "Full apply, full revert, and a verification report that mirrors the same phases.",
  },
  {
    title: "Shared toolkit layer",
    description:
      "Manifest, state tracking, and PowerShell helpers that keep the scripts aligned.",
  },
] as const;

export const FILE_LINKS = [
  {
    title: "GUIDE.md",
    path: "GUIDE.md",
    href: repoFile("GUIDE.md"),
    instruction:
      "The canonical workflow and risk model. Read this first before running any tuning path.",
  },
  {
    title: "launcher.ps1",
    path: "launcher.ps1",
    href: repoFile("launcher.ps1"),
    instruction:
      "Primary entrypoint. Use this when you want the guided product flow instead of browsing folders manually.",
  },
  {
    title: "APPLY-EVERYTHING.ps1",
    path: "APPLY-EVERYTHING.ps1",
    href: repoFile("APPLY-EVERYTHING.ps1"),
    instruction:
      "Aggressive full-stack run for dedicated gaming setups. Includes Windows Update and security trade-offs.",
  },
  {
    title: "REVERT-EVERYTHING.ps1",
    path: "REVERT-EVERYTHING.ps1",
    href: repoFile("REVERT-EVERYTHING.ps1"),
    instruction:
      "Tracked rollback path for the full-stack run, with default-based fallbacks where captured state is unavailable.",
  },
  {
    title: "verify-tweaks.ps1",
    path: "10 verify/verify-tweaks.ps1",
    href: repoFile("10%20verify/verify-tweaks.ps1"),
    instruction:
      "Verification report that checks the same phases exposed by the launcher and guide.",
  },
  {
    title: "BIOS-CHECKLIST.md",
    path: "BIOS-CHECKLIST.md",
    href: repoFile("BIOS-CHECKLIST.md"),
    instruction:
      "Manual BIOS and firmware items such as XMP and ReBAR that the scripts cannot change for you.",
  },
] as const;

export const FAQ_ITEMS = [
  {
    question: "What should I run first?",
    answer:
      "Read GUIDE.md, then start from launcher.ps1. The launcher is the main entrypoint and mirrors the same phases as the guide.",
  },
  {
    question: "Do I need to run everything?",
    answer:
      "No. The toolkit is organized so you can run only the phases that match your machine and your tolerance for trade-offs.",
  },
  {
    question: "What is the risky path?",
    answer:
      "APPLY-EVERYTHING.ps1 is the aggressive path. It bundles service, registry, cleanup, Windows Update, and security trade-off changes into one run.",
  },
  {
    question: "How do I undo changes?",
    answer:
      "Use REVERT-EVERYTHING.ps1 for the tracked full rollback path, then reboot and run Verify if you want to confirm the result.",
  },
  {
    question: "Why run Verify?",
    answer:
      "Verify tells you which checks passed, which settings were already present, which ones drifted, and which checks were unsupported on your machine.",
  },
] as const;
