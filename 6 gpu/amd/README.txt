AMD GPU OPTIMIZATION
Windows 11 Gaming Optimization Guide
============================================

== STEP 1: Clean Driver Install ==

Tool: AMD Cleanup Utility
  Download: https://www.amd.com/en/resources/support-articles/faqs/GPU-601.html
  What it does: Completely removes existing AMD drivers before a fresh
    install. Prevents driver conflicts and leftover files.
  How to use:
    1. Download and run AMD Cleanup Utility
    2. It will reboot into Safe Mode and remove all AMD drivers
    3. After reboot, install fresh drivers from amd.com/en/support

  Alternative: DDU (Display Driver Uninstaller)
    Download: https://www.guru3d.com/download/display-driver-uninstaller-download/
    More thorough but manual process.

== STEP 2: AMD Adrenalin Software Settings ==

Open AMD Software: Adrenalin Edition > Gaming tab:

  Global Graphics Settings:
    - Radeon Anti-Lag: Enabled (reduces input lag)
    - Radeon Boost: Enabled (lowers resolution during fast movement)
    - Radeon Image Sharpening: Enabled (compensates for Radeon Boost)
    - Wait for Vertical Refresh: Off, unless application specifies
    - Frame Rate Target Control: Set to monitor refresh rate
    - Texture Filtering Quality: Performance
    - Tessellation Mode: Override application settings > Off (for esports)

  Global Display Settings:
    - FreeSync: Enabled (if your monitor supports it)
    - GPU Scaling: On
    - Scaling Mode: Full Panel

== STEP 3: Smart Access Memory (SAM) ==

  What it does: AMD's version of Resizable BAR. Allows CPU to access
    full GPU VRAM. Can boost FPS 5-15% in supported games.
  Requirements:
    - AMD Ryzen 3000 series or newer CPU
    - AMD Radeon RX 5000 series or newer GPU
    - Compatible motherboard with AGESA 1.1.0.0 or newer BIOS
    - Above 4G Decoding enabled in BIOS
    - CSM disabled in BIOS
  How to check: AMD Software > Performance > Tuning >
    Smart Access Memory should show "Enabled"

== STEP 4: Performance Tuning (Optional) ==

  In AMD Software > Performance > Tuning:
    - Enable GPU Tuning
    - Use "Auto Overclock GPU" for safe automatic overclocking
    - Or "Auto Undervolt GPU" for lower temps with similar performance
    - Set fan curve: target GPU temp under 85°C junction
