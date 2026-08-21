<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="List Scanner App Icon">
</p>

<h1 align="center">M3 File Engine — List Scanner</h1>

<p align="center">
  <b>Universal File Matcher & Batch Copier for Windows</b><br>
  <i>Compiled into a high-performance, standalone, zero-dependency executable with native HD icon support.</i>
</p>

<p align="center">
  <a href="#features"><img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows" alt="Platform"></a>
  <a href="#version"><img src="https://img.shields.io/badge/Version-1.0.0-00b4d8?style=for-the-badge" alt="Version"></a>
  <a href="#author"><img src="https://img.shields.io/badge/Author-Meet%20Mistry-7209b7?style=for-the-badge" alt="Author"></a>
  <a href="#license"><img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License"></a>
</p>

---

## 📌 Repository Overview & GitHub Details

| Field | Details |
| :--- | :--- |
| **Description** | Universal file scanner, matcher, and batch copier compiled into a standalone Windows executable. Matches items from `list.txt` and organizes them into timestamped output folders with verification reports. |
| **Topics** | `powershell`, `windows-utility`, `file-scanner`, `batch-copier`, `standalone-executable`, `csharp`, `file-matcher`, `productivity-tool`, `automation`, `desktop-app` |

---

## ✨ Features

- ⚡ **Single Standalone Executable (`List Scanner.exe`)**: Completely portable. Copy only `List Scanner.exe` into any working directory alongside `list.txt` and run—no `.ps1` or `.bat` files required in that directory!
- 🎨 **High-Definition Native Icon**: Embedded 256x256 HD PNG icon built directly from high-resolution vector artwork (`assets/icon.png`).
- 🖥️ **Auto-Maximized Terminal Window**: Automatically launches in a full-screen, maximized PowerShell console window with clear status updates.
- 🎯 **Universal Extension Support**: Scans and matches **any** file format (`.png`, `.jpg`, `.pdf`, `.zip`, `.mp4`, `.exe`, `.doc`, etc.) specified in `list.txt`.
- 🛡️ **Smart Application Isolation**: Protects application binaries (`List Scanner.exe`, build scripts, engine files) from being matched or copied.
- 📊 **Unified Stream & Detailed Verification Reports**: Real-time progress monitoring followed by automated file integrity verification and detailed report files (`Missing Items.txt`, `Multiple Matches.txt`, `Copy Failures.txt`).

---

## 📂 Repository Structure

```
yo/
├── assets/
│   ├── icon.png               # High-Resolution HD App Icon (1024x1024)
│   └── icon.ico               # Auto-generated 256x256 multi-res Win32 Icon resource
├── src/
│   └── M3 File Engine.ps1     # Universal File Matcher & Copier Core Engine
├── build/
│   └── Build-Exe.ps1          # Automated C# / Win32 Standalone Executable Compiler
├── List Scanner.exe            # Ready-to-use Standalone Windows Executable (Version 1.0)
├── list.txt                   # Target items list file
├── .gitignore                 # GitHub ignore rules
└── README.md                  # Documentation & user guide
```

---

## 🚀 Quick Start / How to Use

### Step 1: Copy Executable
Copy **`List Scanner.exe`** into the folder containing the files you wish to scan.

### Step 2: Create `list.txt`
In the same folder, create a plain text file named **`list.txt`** with item names (one per line).

```text
az1
photo2.jpg
report_2026.pdf
```

> **Note**: You can specify item names with or without file extensions:
> - Without extension (`az1`): Matches all files sharing the base name `az1` regardless of extension (`az1.png`, `az1.pdf`, etc.).
> - With extension (`photo2.jpg`): Performs exact filename matching.

### Step 3: Run `List Scanner.exe`
Double-click **`List Scanner.exe`**.

The engine will:
1. Open in a maximized console window.
2. Scan the current folder for matching items from `list.txt`.
3. Create a timestamped output directory: `List Items (dd-MM-yyyy - HH.mm.ss)`.
4. Copy all matched files and perform post-copy verification.
5. Generate report logs inside `List Items (...)/Reports/`.

---

## 🛠️ How to Build from Source

If you modify `src/M3 File Engine.ps1` or update `assets/icon.png`, you can re-compile `List Scanner.exe` with a single command using Windows' built-in C# compiler (`csc.exe`):

Open PowerShell in the repository root and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "build/Build-Exe.ps1"
```

The build script will:
1. Generate `assets/icon.ico` from `assets/icon.png`.
2. Embed the script into a C# host template with full Win32 assembly metadata (Company: *Meet Mistry*, Version: *1.0.0.0*).
3. Compile a new standalone `List Scanner.exe` in the root folder.

---

## 📋 Metadata Specs

- **File Description**: `List Scanner - Universal File Matcher & Copier Engine`
- **Company**: `Meet Mistry`
- **Product Name**: `M3 File Engine - List Scanner`
- **Version**: `1.0.0`
- **Copyright**: `Copyright © 2026 Meet Mistry. All rights reserved.`

---

## 👤 Author & License

Created by **Meet Mistry**.

Distributed under the **MIT License**. See `LICENSE` for details.
