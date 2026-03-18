GAMING PREREQUISITES
Windows 11 Gaming Optimization Guide
============================================

Many games require Visual C++ Redistributables and the legacy DirectX
runtime to run. Missing these causes errors like:

  "VCRUNTIME140.dll was not found"
  "MSVCP120.dll was not found"
  "d3dx9_43.dll was not found"

This step installs ALL versions automatically so you never hit these.

== HOW TO USE ==

  1. Right-click "install-runtimes.ps1"
  2. Select "Run with PowerShell"
  3. If prompted about execution policy, type Y and press Enter
  4. Wait for all downloads and installations to complete (~5 minutes)

  OR open PowerShell as Admin and run:
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    .\install-runtimes.ps1

== WHAT IT INSTALLS ==

  Visual C++ Redistributables:
    - 2005 SP1 (x86 + x64)
    - 2008 SP1 (x86 + x64)
    - 2010 SP1 (x86 + x64)
    - 2012 Update 4 (x86 + x64)
    - 2013 (x86 + x64)
    - 2015-2022 (x86 + x64) — covers 2015, 2017, 2019, and 2022

  DirectX:
    - June 2010 Legacy Runtime (needed by many older games)
    - Note: DirectX 12 is built into Windows 11, but the legacy
      runtime adds DX9/DX10 components that some games still need.

== REQUIRES ==

  - Internet connection (downloads ~200MB total)
  - Administrator privileges
  - ~5 minutes to complete
