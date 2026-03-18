POWER PLAN — Windows 11 Gaming Optimization
============================================

What this does:
  Activates the hidden "Ultimate Performance" power plan, which
  keeps your CPU at maximum clock speed and disables power-saving
  features that can cause micro-stutters during gaming.

How to use:
  1. Right-click "enable-ultimate-performance.bat"
  2. Select "Run as administrator"
  3. Done! The plan is now active.

What it changes:
  - CPU minimum state: 100% (no downclocking)
  - Hard disk timeout: 0 (never spin down)
  - USB selective suspend: Disabled
  - PCI Express link state: Off (no power saving on GPU bus)

To revert:
  Open Settings > System > Power > Power mode
  Select "Balanced" (the Windows default)
  Or run in admin Command Prompt:
    powercfg -setactive SCHEME_BALANCED

Laptop users:
  This plan keeps your CPU running full speed even on battery,
  which drains the battery much faster. Switch to "Balanced"
  when you're not gaming.
