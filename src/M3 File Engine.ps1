# ============================================================
# M3 FILE ENGINE
# Universal File Matcher & Copier
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# COLORS
# ------------------------------------------------------------

$Cyan   = "Cyan"
$Green  = "Green"
$Yellow = "Yellow"
$Red    = "Red"
$White  = "White"
$Gray   = "DarkGray"

# ------------------------------------------------------------
# FLEXIBLE FILE MATCHER FUNCTION
# ------------------------------------------------------------

function Get-MatchedFiles {
    param (
        [string]$TargetEntry,
        [array]$Files,
        [string]$SelectedMode = "1"
    )

    if ([string]::IsNullOrWhiteSpace($TargetEntry) -or -not $Files) {
        return @{ Matches = @(); Type = "None" }
    }

    $Ext = [System.IO.Path]::GetExtension($TargetEntry)

    # Mode 1 or Mode 2: Exact Filename Match
    if ($SelectedMode -eq "1" -or $SelectedMode -eq "2") {
        $DirectNameMatches = @($Files | Where-Object { $_.Name -ieq $TargetEntry })
        if ($DirectNameMatches.Count -gt 0) {
            return @{ Matches = $DirectNameMatches; Type = "Exact" }
        }
    }

    # Mode 1 or Mode 3: Exact BaseName Match (if no extension supplied)
    if ($SelectedMode -eq "1" -or $SelectedMode -eq "3") {
        if ([string]::IsNullOrWhiteSpace($Ext)) {
            $BaseMatches = @($Files | Where-Object { $_.BaseName -ieq $TargetEntry })
            if ($BaseMatches.Count -gt 0) {
                return @{ Matches = $BaseMatches; Type = "Exact" }
            }
        }
    }

    # Mode 1 or Mode 4: Whole-Text Substring Match
    if ($SelectedMode -eq "1" -or $SelectedMode -eq "4") {
        $SubstringMatches = @(
            $Files | Where-Object {
                $_.Name.IndexOf($TargetEntry, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
            }
        )
        if ($SubstringMatches.Count -gt 0) {
            return @{ Matches = $SubstringMatches; Type = "Partial" }
        }
    }

    return @{ Matches = @(); Type = "None" }
}

# ------------------------------------------------------------
# SOURCE DIRECTORY
# ------------------------------------------------------------

if ($env:M3_WORKING_DIR -and (Test-Path -LiteralPath $env:M3_WORKING_DIR)) {
    $Root = $env:M3_WORKING_DIR
} else {
    $Root = [System.IO.Directory]::GetCurrentDirectory()
}
Set-Location $Root

$BatName  = "M3 File Engine.bat"
$PsName   = "M3 File Engine.ps1"
$ListName = "list.txt"

# ------------------------------------------------------------
# CHECK LIST
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $ListName)) {

    Clear-Host

    Write-Host ""
    Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
    Write-Host " |                           M3 FILE ENGINE                                 |" -ForegroundColor $Cyan
    Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "       [ ERROR ] list.txt was not found." -ForegroundColor $Red
    Write-Host ""
    Write-Host "       Place list.txt in the folder: $Root" -ForegroundColor $Yellow
    Write-Host ""

    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Read-Host "Press Enter to exit"
    }
    exit
}

# ------------------------------------------------------------
# TIMESTAMP
# ------------------------------------------------------------

$Stamp = Get-Date -Format "dd-MM-yyyy - HH.mm.ss"

$OutputName = "List Items ($Stamp)"
$OutputPath = Join-Path $Root $OutputName

$ReportPath = Join-Path $OutputPath "Reports"

# ------------------------------------------------------------
# CREATE OUTPUT
# ------------------------------------------------------------

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null

$MissingReport  = Join-Path $ReportPath "Missing Items.txt"
$CopyReport     = Join-Path $ReportPath "Copy Failures.txt"
$VerifyReport   = Join-Path $ReportPath "Verification Failures.txt"
$MultipleReport = Join-Path $ReportPath "Multiple Matches.txt"
$PartialReport  = Join-Path $ReportPath "Partial Matches.txt"

# ------------------------------------------------------------
# SOURCE FILES
# ------------------------------------------------------------

$AppFiles = @(
    "List Scanner.exe",
    "List Scanner.bat",
    "M3 File Engine.ps1",
    "M3 File Engine.bat",
    "Build-Exe.ps1",
    "list.txt",
    "Runner_Generated.cs"
)

$SourceFiles = Get-ChildItem -LiteralPath $Root -File |
    Where-Object {
        $AppFiles -notcontains $_.Name
    }

$TotalFiles = $SourceFiles.Count

# ------------------------------------------------------------
# READ & CLEAN LIST
# ------------------------------------------------------------

$ListItems = Get-Content -LiteralPath $ListName |
    ForEach-Object {
        $clean = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) { return }
        $clean = $clean -replace '^\d+[\.\)]\s*', ''
        $clean = $clean -replace '^[*\-\s\u2022]+', ''
        $clean.Trim()
    } |
    Where-Object { $_ -ne "" }

$ListCount = $ListItems.Count

# ------------------------------------------------------------
# HEADER
# ------------------------------------------------------------

# ------------------------------------------------------------
# INTERACTIVE MODE SELECTION MENU
# ------------------------------------------------------------

Clear-Host
try {
    if ($Host.Name -eq 'ConsoleHost') {
        $maxSize = $Host.UI.RawUI.MaxPhysicalWindowSize
        if ($maxSize.Width -gt 0 -and $maxSize.Height -gt 0) {
            $Host.UI.RawUI.WindowSize = $maxSize
        }
    }
} catch {}

Write-Host ""
Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
Write-Host " |  M3 FILE ENGINE                                    Universal File Matcher|" -ForegroundColor $Cyan
Write-Host " |  Created by Meet Mistry                                                  |" -ForegroundColor $Cyan
Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
Write-Host ""

Write-Host " Select Matching Mode:" -ForegroundColor $White
Write-Host ""
Write-Host "   [1] ALL MODES (Default - Press Enter)" -ForegroundColor $Green
Write-Host "       - Full Filename with extension (e.g. report.pdf)" -ForegroundColor $Gray
Write-Host "       - BaseName without extension (e.g. report)" -ForegroundColor $Gray
Write-Host "       - Embedded Substring / Partial ID (e.g. 8261 inside INV_8261_final.pdf)" -ForegroundColor $Gray
Write-Host ""
Write-Host "   [2] Full Filename with Extension Only (e.g. report.pdf)" -ForegroundColor $Yellow
Write-Host "   [3] BaseName without Extension Only (e.g. report)" -ForegroundColor $Yellow
Write-Host "   [4] Embedded Substring / Partial ID Only (e.g. 8261)" -ForegroundColor $Yellow
Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray
Write-Host ""

$UserChoice = Read-Host " Enter choice [1-4] (Default is 1)"
if ([string]::IsNullOrWhiteSpace($UserChoice)) { $UserChoice = "1" }
if ($UserChoice -notin @("1", "2", "3", "4")) { $UserChoice = "1" }

$ModeLabel = switch ($UserChoice) {
    "1" { "ALL MODES (Filename, BaseName & Embedded Substring)" }
    "2" { "Full Filename with Extension Only" }
    "3" { "BaseName without Extension Only" }
    "4" { "Embedded Substring / Partial ID Only" }
}

Clear-Host

Write-Host ""
Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
Write-Host " |  M3 FILE ENGINE                                    Universal File Matcher|" -ForegroundColor $Cyan
Write-Host " |  Created by Meet Mistry                                                  |" -ForegroundColor $Cyan
Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
Write-Host ""

Write-Host " [01] SCAN" -ForegroundColor $White
Write-Host "      Files detected       : $TotalFiles"

Write-Host ""
Write-Host " [02] TARGET LIST" -ForegroundColor $White
Write-Host "      list.txt entries     : $ListCount"

Write-Host ""
Write-Host " [03] OUTPUT" -ForegroundColor $White
Write-Host "      Folder               : $OutputName"
Write-Host "      Reports              : Reports"
Write-Host "      Status               : [ OK ]" -ForegroundColor $Green

Write-Host ""
Write-Host " [04] MATCH + COPY" -ForegroundColor $White
Write-Host "      Source               : $Root"
Write-Host "      Destination          : $OutputName"
Write-Host "      Matching Mode        : $ModeLabel" -ForegroundColor $Cyan

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray
Write-Host ""

# ------------------------------------------------------------
# COUNTERS
# ------------------------------------------------------------

$MatchedEntries      = 0
$MatchedFiles        = 0
$Missing             = 0
$CopyFailures        = 0
$Copied              = 0
$MultipleCount       = 0
$PartialMatchesCount = 0

$MissingItems        = @()
$CopyFailuresList    = @()
$MultipleMatches     = @()
$PartialMatchesList  = @()

# ------------------------------------------------------------
# MATCH + COPY
# ------------------------------------------------------------

foreach ($Entry in $ListItems) {

    $Entry = $Entry.Trim()

    if ([string]::IsNullOrWhiteSpace($Entry)) {
        continue
    }

    $MatchResult = Get-MatchedFiles -TargetEntry $Entry -Files $SourceFiles -SelectedMode $UserChoice
    $Matches   = $MatchResult.Matches
    $MatchType = $MatchResult.Type

    if ($MatchType -eq "Partial") {
        $PartialMatchesCount++
        foreach ($MFile in $Matches) {
            $PartialMatchesList += "LIST ENTRY FROM list.txt : $Entry"
            $PartialMatchesList += "MATCHED FILENAME ON DISK : $($MFile.Name)"
            $PartialMatchesList += "--------------------------------------------------------------------------"
        }
    }

    if ($Matches.Count -gt 1) {

        $MultipleCount++

        $Block = @()

        $Block += "MULTIPLE MATCH: $Entry"
        $Block += ""
        $Block += "Reason:"
        $Block += "Multiple files matching '$Entry' were found in the working directory."
        $Block += ""
        $Block += "Matched files:"

        foreach ($Match in $Matches) {
            $Block += "- $($Match.Name)"
        }

        $Block += ""
        $Block += "Action:"
        $Block += "All matching files were copied."
        $Block += ""
        $Block += "--------------------------------------------------------------------------"
        $Block += ""

        $MultipleMatches += $Block

        Write-Host "      [MULTI] $Entry -> $($Matches.Count) files" -ForegroundColor $Yellow
    }

    # --------------------------------------------------------
    # Missing
    # --------------------------------------------------------

    if ($Matches.Count -eq 0) {

        $Missing++

        $MissingItems += $Entry

        Write-Host "      [MISS] $Entry" -ForegroundColor $Yellow

        continue
    }

    $MatchedEntries++

    # --------------------------------------------------------
    # Copy matches
    # --------------------------------------------------------

    foreach ($File in $Matches) {

        $MatchedFiles++

        if ($MatchType -eq "Partial") {
            Write-Host "      [PARTIAL COPY] $($File.Name) (Matched '$Entry')" -ForegroundColor $Cyan
        } else {
            Write-Host "      [COPY] $($File.Name)" -ForegroundColor $Cyan
        }

        $DestinationFile = Join-Path $OutputPath $File.Name

        try {

            Copy-Item `
                -LiteralPath $File.FullName `
                -Destination $DestinationFile `
                -Force `
                -ErrorAction Stop

            if (Test-Path -LiteralPath $DestinationFile) {

                $Copied++

                Write-Host "      [ OK ] $($File.Name)" -ForegroundColor $Green

            }
            else {

                throw "Destination file was not created."
            }

        }
        catch {

            $CopyFailures++

            $CopyFailuresList += $File.Name

            Write-Host "      [FAIL] $($File.Name)" -ForegroundColor $Red
        }
    }
}

# ------------------------------------------------------------
# WRITE MISSING REPORT
# ------------------------------------------------------------

if ($MissingItems.Count -gt 0) {

    $MissingHeader = @(
        "==========================================================================",
        "                         MISSING ITEMS REPORT",
        "==========================================================================",
        "The following entries from list.txt could not be found or matched in the",
        "working directory.",
        "Total Missing Entries: $($MissingItems.Count)",
        "--------------------------------------------------------------------------",
        ""
    )
    $MissingContent = $MissingHeader + ($MissingItems | ForEach-Object { "- $_" }) + @("--------------------------------------------------------------------------")
    $MissingContent | Set-Content -LiteralPath $MissingReport -Encoding UTF8
}

# ------------------------------------------------------------
# WRITE COPY FAILURE REPORT
# ------------------------------------------------------------

if ($CopyFailuresList.Count -gt 0) {

    $CopyFailHeader = @(
        "==========================================================================",
        "                         COPY FAILURES REPORT",
        "==========================================================================",
        "The following files could not be copied to the destination folder due to",
        "file permissions or system I/O errors.",
        "Total Copy Failures: $($CopyFailuresList.Count)",
        "--------------------------------------------------------------------------",
        ""
    )
    $CopyFailContent = $CopyFailHeader + ($CopyFailuresList | ForEach-Object { "- $_" }) + @("--------------------------------------------------------------------------")
    $CopyFailContent | Set-Content -LiteralPath $CopyReport -Encoding UTF8
}

# ------------------------------------------------------------
# WRITE MULTIPLE MATCH REPORT
# ------------------------------------------------------------

if ($MultipleMatches.Count -gt 0) {

    $MultiHeader = @(
        "==========================================================================",
        "                       MULTIPLE MATCHES REPORT",
        "==========================================================================",
        "Multiple files matched the same entry from list.txt. All matching files",
        "were copied to the destination folder.",
        "Total Multiple Match Conflicts: $MultipleCount",
        "--------------------------------------------------------------------------",
        ""
    )
    $MultiContent = $MultiHeader + $MultipleMatches
    $MultiContent | Set-Content -LiteralPath $MultipleReport -Encoding UTF8
}

# ------------------------------------------------------------
# WRITE PARTIAL MATCHES REPORT
# ------------------------------------------------------------

if ($PartialMatchesList.Count -gt 0) {

    $PartialHeader = @(
        "==========================================================================",
        "                     PARTIAL / EMBEDDED MATCHES REPORT",
        "==========================================================================",
        "The following entries from list.txt were matched by searching for the",
        "whole exact entry text as an embedded substring inside filenames.",
        "Total Partial Matches: $PartialMatchesCount",
        "--------------------------------------------------------------------------",
        ""
    )
    $PartialReportContent = $PartialHeader + $PartialMatchesList
    $PartialReportContent | Set-Content -LiteralPath $PartialReport -Encoding UTF8
}

# ------------------------------------------------------------
# VERIFICATION
# ------------------------------------------------------------

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray
Write-Host ""
Write-Host " [05] VERIFICATION" -ForegroundColor $White
Write-Host ""

$Verified = 0
$VerifyFailures = 0

$VerifyFailuresList = @()

foreach ($Entry in $ListItems) {

    $Entry = $Entry.Trim()

    if ([string]::IsNullOrWhiteSpace($Entry)) {
        continue
    }

    $MatchResult = Get-MatchedFiles -TargetEntry $Entry -Files $SourceFiles -SelectedMode $UserChoice
    $Matches = $MatchResult.Matches

    foreach ($File in $Matches) {

        $DestinationFile = Join-Path $OutputPath $File.Name

        if (-not (Test-Path -LiteralPath $DestinationFile)) {

            $VerifyFailures++

            $VerifyFailuresList += $File.Name

            continue
        }

        try {

            $DestinationInfo = Get-Item -LiteralPath $DestinationFile

            if ($File.Length -eq $DestinationInfo.Length) {

                $Verified++

            }
            else {

                $VerifyFailures++

                $VerifyFailuresList += $File.Name
            }

        }
        catch {

            $VerifyFailures++

            $VerifyFailuresList += $File.Name
        }
    }
}

# ------------------------------------------------------------
# WRITE VERIFICATION REPORT
# ------------------------------------------------------------

if ($VerifyFailuresList.Count -gt 0) {

    $VerifyFailHeader = @(
        "==========================================================================",
        "                     VERIFICATION FAILURES REPORT",
        "==========================================================================",
        "The following files failed post-copy byte verification check (file size",
        "mismatch or creation error).",
        "Total Verification Failures: $($VerifyFailuresList.Count)",
        "--------------------------------------------------------------------------",
        ""
    )
    $VerifyFailContent = $VerifyFailHeader + ($VerifyFailuresList | ForEach-Object { "- $_" }) + @("--------------------------------------------------------------------------")
    $VerifyFailContent | Set-Content -LiteralPath $VerifyReport -Encoding UTF8
}

# ------------------------------------------------------------
# FINAL REPORT
# ------------------------------------------------------------

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray
Write-Host ""

Write-Host ""
Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
Write-Host " |                           FINAL REPORT                                   |" -ForegroundColor $Cyan
Write-Host " +--------------------------------------------------------------------------+" -ForegroundColor $Cyan
Write-Host ""

Write-Host "      Files detected          : $TotalFiles"
Write-Host "      Names in list.txt       : $ListCount"
Write-Host ""

Write-Host "      Matched entries         : $MatchedEntries"
Write-Host "      Files matched           : $MatchedFiles"
Write-Host "      Partial/Embedded matches: $PartialMatchesCount"
Write-Host "      Missing entries         : $Missing"
Write-Host "      Multiple matches        : $MultipleCount"
Write-Host "      Successfully copied     : $Copied"
Write-Host "      Copy failures           : $CopyFailures"
Write-Host "      Verification passed     : $Verified"
Write-Host "      Verification failures   : $VerifyFailures"

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray

# ------------------------------------------------------------
# STATUS
# ------------------------------------------------------------

if (
    $Missing -eq 0 -and
    $CopyFailures -eq 0 -and
    $VerifyFailures -eq 0
) {

    Write-Host ""
    Write-Host "      +----------------------------------------------------------------+" -ForegroundColor $Green
    Write-Host "      |                         [ SUCCESS ]                            |" -ForegroundColor $Green
    Write-Host "      |                                                                |" -ForegroundColor $Green
    Write-Host "      |              All files copied and verified.                    |" -ForegroundColor $Green
    Write-Host "      +----------------------------------------------------------------+" -ForegroundColor $Green

}
else {

    Write-Host ""
    Write-Host "      +----------------------------------------------------------------+" -ForegroundColor $Yellow
    Write-Host "      |                       [ COMPLETED ]                            |" -ForegroundColor $Yellow
    Write-Host "      |                                                                |" -ForegroundColor $Yellow
    Write-Host "      |                 Review the Reports folder.                     |" -ForegroundColor $Yellow
    Write-Host "      +----------------------------------------------------------------+" -ForegroundColor $Yellow
}

# ------------------------------------------------------------
# REPORTS
# ------------------------------------------------------------

Write-Host ""

if ($PartialMatchesCount -gt 0) {
    Write-Host "      Partial / Embedded matches : Reports\Partial Matches.txt ($PartialMatchesCount)" -ForegroundColor $Cyan
}

if ($Missing -gt 0) {
    Write-Host "      Missing entries            : Reports\Missing Items.txt" -ForegroundColor $Yellow
}

if ($MultipleCount -gt 0) {
    Write-Host "      Multiple matches           : Reports\Multiple Matches.txt" -ForegroundColor $Yellow
}

if ($CopyFailures -gt 0) {
    Write-Host "      Copy failures              : Reports\Copy Failures.txt" -ForegroundColor $Red
}

if ($VerifyFailures -gt 0) {
    Write-Host "      Verification failures     : Reports\Verification Failures.txt" -ForegroundColor $Red
}

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray

Write-Host "      Output:"
Write-Host "      $OutputPath"

Write-Host ""
Write-Host "      Reports:"
Write-Host "      $ReportPath"

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray
Write-Host ""
Write-Host "                         M3 File Engine" -ForegroundColor $Cyan
Write-Host "                         Created by Meet Mistry" -ForegroundColor $Gray
Write-Host ""
Write-Host "                         [ Press any key to close ]" -ForegroundColor $White
Write-Host ""

# ------------------------------------------------------------
# WAIT
# ------------------------------------------------------------

try {
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    Read-Host "Press Enter to exit"
}

exit
