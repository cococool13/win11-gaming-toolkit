============================================================
4 services/individual/ — DEPRECATED in favor of disable-services.ps1
============================================================
CURSOR-AUDIT #21

The *-disable.bat / *-enable.bat pairs in this folder were the
original per-service toggle path. They still work and still ship,
but they BYPASS the toolkit manifest at
%ProgramData%\Win11GamingToolkit\state\manifest.json.

Consequences of using these .bat files:
  - REVERT-EVERYTHING.ps1 cannot restore the per-service start mode
    you had before running the .bat — it has no captured before-state.
  - 4 services/revert-all.bat (now itself a wrapper around
    4 services/revert-all.ps1) falls back to fixed defaults for any
    service not in the manifest. That's "close enough" for most users
    but not the exact prior state.

RECOMMENDED PATHS (manifest-tracked):
  - Disable: 4 services\disable-services.ps1   (smart preview + apply)
  - Revert:  4 services\revert-all.ps1         (manifest-driven restore)

KEEP USING THESE .BAT FILES IF:
  - You want a quick one-service-at-a-time toggle from File Explorer
  - You're OK with revert returning the service to Windows default
    rather than to your exact pre-toolkit state

The .bat files are not slated for removal; they are documented as
"works, but not the preferred path" so users know which surface to
prefer for safety-critical revert.
