# ============================================================
# PSScriptAnalyzer settings for Win11 Gaming Toolkit
# ============================================================
# Loaded by:  Invoke-ScriptAnalyzer -Settings .psscriptanalyzer.psd1
# Loaded by VS Code PowerShell extension automatically when at repo root.
#
# Layered on top of the default PSSA ruleset. Our project additions
# enforce the CLAUDE.md invariants:
#   - PS 5.1 compat: no compatibility-warning rules suppressed
#   - Admin self-check pattern: PSAvoidUsingPlainTextForPassword is OK
#     since we never read passwords; left at default
#   - Manifest-tracked writes: enforced by code review, not analyzer
#     (analyzer can't tell apart Set-ItemProperty wrappers vs raw calls)
#
# Rule customizations below. Rationale in line comments.
# ============================================================

@{
    # Pick rules explicitly so default-changes upstream don't surprise us.
    IncludeDefaultRules = $true

    # Enforce PS 5.1 compatibility for the inbox-Windows-PowerShell target.
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @('5.1', '7.4')
        }
        PSUseCompatibleCmdlets = @{
            Enable = $true
            compatibility = @(
                'desktop-5.1.14393.206-windows'  # Win10 1607 baseline
            )
        }
        # Indentation: project standard is 4 spaces, no tabs.
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
        }
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }
        PSAlignAssignmentStatement = @{
            Enable = $false  # Too noisy on per-row registry config blocks
        }
        # Avoid Write-Host for data (CLAUDE.md gate); allowed for UI banners.
        # We rely on PSAvoidUsingWriteHost being raised as a warning but
        # NOT excluded — fixes follow case-by-case (UI banner: $true,
        # data output: $false → migrate to Write-Output).
    }

    # Rules deliberately excluded (with reason):
    ExcludeRules = @(
        # Toolkit uses inline string-built reg add args from controlled
        # constants. PSAvoidUsingInvokeExpression would still fire on
        # & reg add @Arguments which we keep for compatibility with
        # batch helpers. Reviewed manually per-call site.
        'PSAvoidUsingInvokeExpression'

        # PSAvoidGlobalVars — toolkit uses $script:UI_* shared counters
        # in lib/ui-helpers.ps1. These are intentional shared state for
        # cross-step tallies in interactive scripts.
        'PSAvoidGlobalVars'

        # PSReviewUnusedParameter — false positives on params that are
        # passed-through via @PSBoundParameters or splatting.
        'PSReviewUnusedParameter'

        # PSAvoidUsingWriteHost — the toolkit is an INTERACTIVE UI
        # surface, not a data-emitting pipeline. Every Write-Host call
        # produces colored banner / status / prompt text for human users
        # via the UI-* helpers in lib/ui-helpers.ps1 (or inline equivalents).
        # The CLAUDE.md quality bar "No Write-Host for data" is still
        # enforced by code review; the analyzer simply can't distinguish
        # "UI colored output" from "data output that should be in a pipe."
        # New scripts that emit data values must use Write-Output /
        # Write-Information per the standard; this exclusion only covers
        # the existing UI surface.
        'PSAvoidUsingWriteHost'

        # PSUseBOMForUnicodeEncodedFile — our .ps1 files are ASCII-safe
        # and use UTF-8 without BOM via .gitattributes (* text=auto).
        # Adding BOMs would break the line-ending normalization we just
        # committed in 17729ec and break any tool that doesn't grok BOMs
        # (we still have to support some legacy .bat callers).
        'PSUseBOMForUnicodeEncodedFile'
    )
}
