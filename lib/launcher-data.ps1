function Get-LauncherMenu {
    return @(
        [PSCustomObject]@{
            Title = "Setup"
            Accent = "Cyan"
            Items = @(
                [PSCustomObject]@{ Key = "0"; Label = "Checkpoint"; Summary = "Restore point and registry backup"; Path = "1 backup\create-backup.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "1"; Label = "Runtime prep"; Summary = "VC++, DirectX, and prerequisites"; Path = "0 prerequisites\install-runtimes.ps1"; Type = "ps1" }
            )
        },
        [PSCustomObject]@{
            Title = "Optimize"
            Accent = "White"
            Items = @(
                [PSCustomObject]@{ Key = "2"; Label = "Power plan"; Summary = "Ultimate Performance and power tuning"; Path = "2 power plan\configure-power.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "3"; Label = "Services"; Summary = "Disable background services"; Path = "4 services\disable-services.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "4"; Label = "Registry pack"; Summary = "Apply bundled registry tweaks"; Path = "5 registry tweaks\apply-all.reg"; Type = "reg" },
                [PSCustomObject]@{ Key = "5"; Label = "Timer service"; Summary = "Install timer resolution service"; Path = "5 registry tweaks\individual\install-timer-resolution-service.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "8"; Label = "Security trade-off"; Summary = "Disable VBS / Memory Integrity"; Path = "8 security vs performance\configure-vbs.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "9"; Label = "Cleanup"; Summary = "Debloat and clear temp files"; Path = "MULTI_CLEANUP"; Type = "bundle" }
            )
        },
        [PSCustomObject]@{
            Title = "GPU and Network"
            Accent = "White"
            Items = @(
                [PSCustomObject]@{ Key = "6"; Label = "GPU MSI mode"; Summary = "Lower interrupt latency"; Path = "6 gpu\enable-msi-mode.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "7"; Label = "Network"; Summary = "Adapter-aware optimization"; Path = "7 network\optimize-network.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "D"; Label = "DDU flow"; Summary = "Safe-mode GPU cleanup"; Path = "DduAuto.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "G"; Label = "Driver install"; Summary = "Clean GPU driver install and tune"; Path = "6 gpu\install-gpu-driver.ps1"; Type = "ps1" }
            )
        },
        [PSCustomObject]@{
            Title = "Safety and Verify"
            Accent = "White"
            Items = @(
                [PSCustomObject]@{ Key = "A"; Label = "Apply everything"; Summary = "Aggressive full-stack run"; Path = "APPLY-EVERYTHING.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "R"; Label = "Revert everything"; Summary = "Restore tracked changes"; Path = "REVERT-EVERYTHING.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "V"; Label = "Verify"; Summary = "Check what is applied now"; Path = "10 verify\verify-tweaks.ps1"; Type = "ps1" },
                [PSCustomObject]@{ Key = "W"; Label = "WinUtil"; Summary = "Chris Titus WinUtil launcher"; Path = "9 cleanup\chris-titus-winutil.bat"; Type = "bat" }
            )
        }
    )
}
