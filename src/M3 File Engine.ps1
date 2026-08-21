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
# READ LIST
# ------------------------------------------------------------

$ListItems = Get-Content -LiteralPath $ListName |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

$ListCount = $ListItems.Count

# ------------------------------------------------------------
# HEADER
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

Write-Host ""
Write-Host " --------------------------------------------------------------------------" -ForegroundColor $Gray
Write-Host ""

# ------------------------------------------------------------
# COUNTERS
# ------------------------------------------------------------

$MatchedEntries = 0
$MatchedFiles   = 0
$Missing        = 0
$CopyFailures   = 0
$Copied         = 0
$MultipleCount  = 0

$MissingItems       = @()
$CopyFailuresList   = @()
$MultipleMatches    = @()

# ------------------------------------------------------------
# MATCH + COPY
# ------------------------------------------------------------

foreach ($Entry in $ListItems) {

    $Entry = $Entry.Trim()

    if ([string]::IsNullOrWhiteSpace($Entry)) {
        continue
    }

    # --------------------------------------------------------
    # Determine whether extension was supplied
    # --------------------------------------------------------

    $Extension = [System.IO.Path]::GetExtension($Entry)

    $Matches = @()

    if ([string]::IsNullOrWhiteSpace($Extension)) {

        # ----------------------------------------------------
        # No extension specified.
        #
        # Match every file with the same base name.
        # ----------------------------------------------------

        $Matches = @(
            $SourceFiles |
            Where-Object {
                $_.BaseName -ieq $Entry
            }
        )

        # ----------------------------------------------------
        # Multiple matches detected
        # ----------------------------------------------------

        if ($Matches.Count -gt 1) {

            $MultipleCount++

            $Block = @()

            $Block += "MULTIPLE MATCH: $Entry"
            $Block += ""
            $Block += "Reason:"
            $Block += "The list entry did not specify a file extension."
            $Block += "Multiple files with the same base name were found."
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

    }
    else {

        # ----------------------------------------------------
        # Extension supplied.
        #
        # Match exact filename.
        # ----------------------------------------------------

        $Matches = @(
            $SourceFiles |
            Where-Object {
                $_.Name -ieq $Entry
            }
        )
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

        Write-Host "      [COPY] $($File.Name)" -ForegroundColor $Cyan

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

    $MissingItems |
        Set-Content -LiteralPath $MissingReport -Encoding UTF8
}

# ------------------------------------------------------------
# WRITE COPY FAILURE REPORT
# ------------------------------------------------------------

if ($CopyFailuresList.Count -gt 0) {

    $CopyFailuresList |
        Set-Content -LiteralPath $CopyReport -Encoding UTF8
}

# ------------------------------------------------------------
# WRITE MULTIPLE MATCH REPORT
# ------------------------------------------------------------

if ($MultipleMatches.Count -gt 0) {

    $MultipleMatches |
        Set-Content -LiteralPath $MultipleReport -Encoding UTF8
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

    $Extension = [System.IO.Path]::GetExtension($Entry)

    if ([string]::IsNullOrWhiteSpace($Extension)) {

        $Matches = @(
            $SourceFiles |
            Where-Object {
                $_.BaseName -ieq $Entry
            }
        )

    }
    else {

        $Matches = @(
            $SourceFiles |
            Where-Object {
                $_.Name -ieq $Entry
            }
        )
    }

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

    $VerifyFailuresList |
        Set-Content -LiteralPath $VerifyReport -Encoding UTF8
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

if ($Missing -gt 0) {
    Write-Host "      Missing entries        : Reports\Missing Items.txt" -ForegroundColor $Yellow
}

if ($MultipleCount -gt 0) {
    Write-Host "      Multiple matches       : Reports\Multiple Matches.txt" -ForegroundColor $Yellow
}

if ($CopyFailures -gt 0) {
    Write-Host "      Copy failures          : Reports\Copy Failures.txt" -ForegroundColor $Red
}

if ($VerifyFailures -gt 0) {
    Write-Host "      Verification failures : Reports\Verification Failures.txt" -ForegroundColor $Red
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
