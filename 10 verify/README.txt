VERIFY & BENCHMARK
Windows 11 Gaming Optimization Guide
============================================

After applying all tweaks, use these tools and checks to verify
everything is working and measure your performance improvement.

== BENCHMARKING TOOLS ==

  3DMark (Steam — free demo available)
    https://store.steampowered.com/app/223850/3DMark/
    Best for: GPU performance testing. Run "Time Spy" (DX12)
    or "Fire Strike" (DX11). Compare scores before and after.

  CapFrameX
    https://www.capframex.com/
    Best for: Real-world game benchmarking. Records FPS, frame
    times, 1% lows, and 0.1% lows during actual gameplay.
    More useful than synthetic benchmarks for detecting stuttering.

  UserBenchmark
    https://www.userbenchmark.com/
    Best for: Quick overall system check. Tests CPU, GPU, RAM,
    and SSD in under 2 minutes. Compares against other users
    with the same hardware. Good for spotting underperforming parts.

  UNIGINE Superposition
    https://benchmark.unigine.com/superposition
    Best for: GPU stress testing and thermal stability check.

== VERIFICATION CHECKLIST ==

After all tweaks, verify each one took effect:

  [ ] Power Plan
      Open Settings > System > Power > Power mode
      Should show: "Ultimate Performance" or "Best performance"

  [ ] VBS / Memory Integrity (if you disabled it)
      Press Win+R, type "msinfo32", Enter
      Look for: "Virtualization-based security: Not enabled"

  [ ] Game Mode
      Settings > Gaming > Game Mode
      Should be: On

  [ ] Mouse Acceleration
      Settings > Bluetooth & devices > Mouse > Additional mouse settings
      "Enhance pointer precision" should be: Unchecked

  [ ] HAGS (Hardware-accelerated GPU scheduling)
      Settings > System > Display > Graphics > Change default settings
      Should be: On

  [ ] Services
      Press Win+R, type "services.msc", Enter
      Check that DiagTrack, PhoneSvc, etc. show "Disabled"

  [ ] Registry Tweaks
      Press Win+R, type "regedit", Enter
      Navigate to HKCU\Control Panel\Desktop
      MenuShowDelay should be: 0

  [ ] Network (Nagle)
      Open PowerShell as Admin, run:
        Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" | Where-Object { $_.TCPNoDelay -eq 1 } | Select-Object TCPNoDelay, TcpAckFrequency
      Should show at least one entry with TCPNoDelay = 1

  [ ] Resizable BAR
      For NVIDIA: NVIDIA Control Panel > System Information > Resizable BAR
      For AMD: AMD Software > Performance > Tuning > Smart Access Memory
      For Intel: Intel Arc Control > System Information

== HOW TO BENCHMARK PROPERLY ==

  1. Run your benchmark BEFORE applying any tweaks (baseline)
  2. Write down the scores: FPS, 1% lows, and average frame time
  3. Apply all tweaks, reboot
  4. Run the EXACT same benchmark again with the SAME settings
  5. Compare the results

  Tips:
    - Close all background apps before benchmarking
    - Run the benchmark 3 times and average the results
    - GPU temperature affects performance — let the GPU cool between runs
    - Use CapFrameX for in-game testing (more realistic than synthetic)

== EXPECTED IMPROVEMENTS ==

  These vary by hardware, but typical gains:

  | Tweak                    | Expected FPS Gain |
  |--------------------------|-------------------|
  | VBS/HVCI disabled        | 5-25%             |
  | Power plan + services    | 2-5%              |
  | Registry tweaks          | 1-3% (mostly feel)|
  | Network optimization     | Lower ping, not FPS|
  | GPU driver optimization  | 2-10%             |
  | Debloat + cleanup        | Smoother overall  |

  Total combined: typically 10-30% FPS improvement
  Biggest single gain: Disabling VBS (Step 8)
