# ============================================================
# BUILD SCRIPT FOR STANDALONE LIST SCANNER EXE
# Author: Meet Mistry
# ============================================================

$ErrorActionPreference = "Stop"

$ScriptDir   = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }
$ProjectRoot = (Get-Item $ScriptDir).Parent.FullName
if (-not $ProjectRoot) { $ProjectRoot = $ScriptDir }

$PsScriptPath = Join-Path $ProjectRoot "src\M3 File Engine.ps1"
$PngIconPath  = Join-Path $ProjectRoot "assets\icon.png"
$HdIconPath   = Join-Path $ProjectRoot "assets\icon.ico"
$OutExePath   = Join-Path $ProjectRoot "List Scanner.exe"
$TempCsPath   = Join-Path $ScriptDir "Runner_Generated.cs"

if (-not (Test-Path -LiteralPath $PsScriptPath)) {
    Write-Error "M3 File Engine.ps1 not found at $PsScriptPath"
}

# ------------------------------------------------------------
# GENERATE HD 256x256 .ICO FROM icon.png
# ------------------------------------------------------------
if (Test-Path -LiteralPath $PngIconPath) {
    Write-Host "Generating HD 256x256 Icon from assets/icon.png..." -ForegroundColor Cyan
    try {
        Add-Type -AssemblyName System.Drawing
        $src = [System.Drawing.Image]::FromFile($PngIconPath)
        $bmp = new-object System.Drawing.Bitmap(256, 256)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($src, 0, 0, 256, 256)
        
        $ms = new-object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $ms.ToArray()
        
        $g.Dispose()
        $bmp.Dispose()
        $src.Dispose()
        
        $fs = [System.IO.File]::Create($HdIconPath)
        $bw = new-object System.IO.BinaryWriter($fs)
        $bw.Write([uint16]0)    # Reserved
        $bw.Write([uint16]1)    # Type (1 = ICO)
        $bw.Write([uint16]1)    # Count (1 image)
        $bw.Write([byte]0)      # Width 0 -> 256px
        $bw.Write([byte]0)      # Height 0 -> 256px
        $bw.Write([byte]0)      # Color count
        $bw.Write([byte]0)      # Reserved
        $bw.Write([uint16]1)    # Planes
        $bw.Write([uint16]32)   # Bit count
        $bw.Write([uint32]$pngBytes.Length) # Bytes in resource
        $bw.Write([uint32]22)   # Image offset
        $bw.Write($pngBytes)
        $bw.Close()
        $fs.Close()
        Write-Host "HD Icon created ($HdIconPath)." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not create HD icon from PNG: $_" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# PREPARE C# LAUNCHER CODE WITH ASSEMBLY METADATA
# ------------------------------------------------------------
Write-Host "Reading src/M3 File Engine.ps1..." -ForegroundColor Cyan
$ScriptContent = Get-Content -LiteralPath $PsScriptPath -Raw -Encoding UTF8

# Escape double quotes for C# verbatim string literal
$EscapedScript = $ScriptContent.Replace('"', '""')

$CsCode = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

[assembly: AssemblyTitle("List Scanner")]
[assembly: AssemblyDescription("Universal File Matcher & Copier Engine")]
[assembly: AssemblyConfiguration("Release")]
[assembly: AssemblyCompany("Meet Mistry")]
[assembly: AssemblyProduct("M3 File Engine - List Scanner")]
[assembly: AssemblyCopyright("Copyright © 2026 Meet Mistry. All rights reserved.")]
[assembly: AssemblyTrademark("Meet Mistry")]
[assembly: AssemblyCulture("")]

[assembly: ComVisible(false)]
[assembly: Guid("d3f8a2b1-5e7c-4a9b-8d1e-2f3a4b5c6d7e")]

[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: AssemblyInformationalVersion("1.0.0")]

namespace ListScanner
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            string tempScriptPath = null;
            try
            {
                string exePath = Assembly.GetExecutingAssembly().Location;
                string currentDir = Path.GetDirectoryName(exePath);
                if (string.IsNullOrEmpty(currentDir))
                {
                    currentDir = Directory.GetCurrentDirectory();
                }

                Directory.SetCurrentDirectory(currentDir);
                
                string tempName = "M3_Engine_Runner_" + Guid.NewGuid().ToString("N") + ".ps1";
                tempScriptPath = Path.Combine(Path.GetTempPath(), tempName);
                
                string embeddedScript = @"$EscapedScript";
                
                File.WriteAllText(tempScriptPath, embeddedScript, new UTF8Encoding(false));
                
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + tempScriptPath + "\"";
                psi.WorkingDirectory = currentDir;
                psi.UseShellExecute = true;
                psi.WindowStyle = ProcessWindowStyle.Maximized;
                
                Process proc = Process.Start(psi);
                if (proc != null)
                {
                    proc.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to launch List Scanner:\n\n" + ex.Message, "List Scanner Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                if (!string.IsNullOrEmpty(tempScriptPath) && File.Exists(tempScriptPath))
                {
                    try { File.Delete(tempScriptPath); } catch {}
                }
            }
        }
    }
}
"@

Write-Host "Writing C# source file with Assembly Info..." -ForegroundColor Cyan
[System.IO.File]::WriteAllText($TempCsPath, $CsCode, [System.Text.Encoding]::UTF8)

$CscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path -LiteralPath $CscPath)) {
    $CscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path -LiteralPath $CscPath)) {
    Remove-Item -LiteralPath $TempCsPath -Force -ErrorAction SilentlyContinue
    Write-Error "C# Compiler (csc.exe) not found on system."
}

Write-Host "Compiling professional standalone List Scanner.exe..." -ForegroundColor Cyan

$TargetIcon = if (Test-Path -LiteralPath $HdIconPath) { $HdIconPath } else { $null }

$CscArgs = @(
    "/target:winexe",
    "/nologo",
    "/optimize+",
    "/r:System.Windows.Forms.dll",
    "/out:`"$OutExePath`""
)

if ($TargetIcon) {
    $CscArgs += "/win32icon:`"$TargetIcon`""
}

$CscArgs += "`"$TempCsPath`""

$ArgString = $CscArgs -join " "

$Proc = Start-Process -FilePath $CscPath -ArgumentList $ArgString -NoNewWindow -Wait -PassThru

Remove-Item -LiteralPath $TempCsPath -Force -ErrorAction SilentlyContinue

if ($Proc.ExitCode -eq 0 -and (Test-Path -LiteralPath $OutExePath)) {
    Write-Host ""
    Write-Host "[ SUCCESS ] Professional Standalone List Scanner.exe compiled successfully!" -ForegroundColor Green
    Write-Host "Company: Meet Mistry | Version: 1.0.0.0" -ForegroundColor Cyan
    Write-Host "Output EXE: $OutExePath" -ForegroundColor Yellow
} else {
    Write-Error "Compilation failed with exit code $($Proc.ExitCode)"
}
