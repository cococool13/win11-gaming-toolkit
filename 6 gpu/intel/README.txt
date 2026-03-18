INTEL ARC GPU OPTIMIZATION
Windows 11 Gaming Optimization Guide
============================================

Intel Arc GPUs (A770, A750, A580, etc.) are newer to the discrete GPU
market. Driver maturity has improved significantly since launch.

== STEP 1: Keep Drivers Updated ==

  Download: https://www.intel.com/content/www/us/en/download-center/home.html
  Intel Arc drivers improve rapidly with each update.
  Always use the latest driver — performance gains of 10-30% between
  major driver versions are common.

== STEP 2: Intel Arc Control Settings ==

Open Intel Arc Control > Performance tab:

  Recommended:
    - Disable Vertical Sync (use in-game instead)
    - Texture Filtering Quality: Performance
    - Enable Resizable BAR (check in System Information)

== STEP 3: Resizable BAR ==

  Resizable BAR is CRITICAL for Intel Arc. Performance can drop 20-30%
  without it. Make sure it's enabled:
    1. Enable "Above 4G Decoding" in BIOS
    2. Enable "Resizable BAR" in BIOS
    3. Disable CSM in BIOS
    4. Verify in Intel Arc Control > System Information

== STEP 4: Game-Specific Notes ==

  - Intel Arc works best with DirectX 12 and Vulkan games
  - DX11 performance is weaker — use DX12 mode when available
  - Enable XeSS (Intel's upscaling) where supported for free FPS
