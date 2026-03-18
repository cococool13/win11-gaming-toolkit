NVIDIA GPU OPTIMIZATION
Windows 11 Gaming Optimization Guide
============================================

== STEP 1: Clean Driver Install ==

Tool: NVCleanInstall
  Download: https://www.techpowerup.com/nvcleaninstall/
  What it does: Installs NVIDIA drivers without bloatware (telemetry,
    GeForce Experience, HD Audio if unused). Gives you a minimal,
    clean driver installation.
  How to use:
    1. Download the latest NVIDIA driver from nvidia.com/drivers
    2. Open NVCleanInstall
    3. Select the downloaded driver
    4. Uncheck: GeForce Experience, Telemetry, USB-C Driver (if unused)
    5. Check: "Disable Installer Telemetry"
    6. Install

== STEP 2: NVIDIA Control Panel Settings ==

Right-click Desktop > NVIDIA Control Panel > Manage 3D Settings:

  Global Settings (recommended):
    - Low Latency Mode: Ultra (or On)
    - Max Frame Rate: Set to your monitor's refresh rate + 3
      (e.g., 144Hz monitor = 147 FPS cap)
    - Power Management Mode: Prefer Maximum Performance
    - Texture Filtering - Quality: High Performance
    - Threaded Optimization: Auto
    - Vertical Sync: Off (use in-game or RTSS limiter instead)
    - Shader Cache Size: Unlimited

  For competitive/esports:
    - Image Sharpening: On (0.50, Ignore Film Grain: 0.17)
    - Anisotropic Filtering: Application Controlled
    - FXAA: Off

== STEP 3: NVIDIA Profile Inspector (Advanced) ==

Tool: NVIDIA Profile Inspector
  Download: https://github.com/Orbmu2k/nvidiaProfileInspector/releases
  What it does: Exposes hundreds of hidden driver settings not available
    in the normal control panel.
  Recommended changes:
    - CUDA - Force P2 State: Off (prevents GPU downclocking in games)
    - Preferred OpenGL GPU: Your NVIDIA GPU
    - Frame Rate Limiter V3: Match your monitor refresh rate
    - rBAR - Feature: Enabled (if your motherboard supports it)

== STEP 4: Resizable BAR (ReBAR) ==

  What it does: Allows the CPU to access the full GPU VRAM at once
    instead of in 256MB chunks. Can give 5-15% FPS boost in some games.
  Requirements:
    - NVIDIA RTX 3000 series or newer
    - UEFI BIOS with Above 4G Decoding and Resizable BAR enabled
    - CSM (Compatibility Support Module) disabled in BIOS
  How to check: Open NVIDIA Control Panel > System Information >
    Look for "Resizable BAR: Yes"

== STEP 5: MSI Afterburner (Optional) ==

  Download: https://www.msi.com/Landing/afterburner/graphics-cards
  What it does: GPU overclocking, fan curve control, monitoring overlay.
  Recommended:
    - Set a custom fan curve (keep GPU under 80°C)
    - Use RTSS (included) for frame rate limiting (lower input lag
      than driver-level limiting)
    - Use the overlay to monitor FPS, GPU temp, and usage during games
