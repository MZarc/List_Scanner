<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="List Scanner App Icon">
</p>

<h1 align="center">M3 File Engine — List Scanner</h1>

<p align="center">
  <b>Universal File Matcher & Batch Copier for Windows</b><br>
</p>

<p align="center">
  <a href="#features"><img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows" alt="Platform"></a>
  <a href="#version"><img src="https://img.shields.io/badge/Version-1.0.0-00b4d8?style=for-the-badge" alt="Version"></a>
  <a href="#author"><img src="https://img.shields.io/badge/Author-Meet%20Mistry-7209b7?style=for-the-badge" alt="Author"></a>
  <a href="#license"><img src="https://img.shields.io/badge/License-MIT-success?style=for-the-badge" alt="License"></a>
</p>

---

## ✨ Features

- ⚡ **Single Standalone Executable (`List Scanner.exe`)**: Completely portable. Copy only `List Scanner.exe` into any working directory alongside `list.txt` and run! No `.ps1` or `.bat` files required in that directory!
- 🎛️ **Interactive Mode Selection on Launch**: Choose between 4 flexible matching modes on launch, defaulting to **ALL MODES** automatically by simply pressing **Enter**.
- 🎯 **Universal Extension Support**: Scans and matches **any** file format (`.png`, `.jpg`, `.pdf`, `.zip`, `.mp4`, `.exe`, `.doc`, `.csv`, etc.) specified in `list.txt`.
- 🔍 **Flexible Embedded Substring Matching**: Locates files where list IDs appear anywhere as embedded substrings inside complex filenames (e.g. `8261` inside `INV_8261_final.pdf`).
- 🧹 **Automatic Bullet & List Sanitization**: Automatically strips list formatting prefixes (`- `, `* `, `• `, `1. `, `1) `) copied from Markdown, Word, or emails.
- 🛡️ **Smart Application Isolation**: Protects application binaries (`List Scanner.exe`, build scripts, engine files) from being matched or copied.
- 📄 **Standardized Professional Reports**: Generates unified, beautifully structured report files (`Missing Items.txt`, `Partial Matches.txt`, `Multiple Matches.txt`, `Copy Failures.txt`, `Verification Failures.txt`).

---

## 📂 Repository Structure

```
List_Scanner/
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
Invoice1
Invoice2.pdf
- N002141726498
Tax Report
8261
```

> **Note**: Flexible List Inputs Supported:
> - **Without extension** (`Invoice1`): Matches base name `Invoice1` across any extension (`Invoice1.pdf`, `Invoice1.docx`, etc.).
> - **With extension** (`Invoice2.pdf`): Performs exact filename matching.
> - **Bulleted / Formatted lines** (`- N002141726498`): Automatically strips bullet symbols (`- `, `* `, `1. `) to extract the core search ID.
> - **Embedded Substrings** (`8261`): Matches files containing `8261` anywhere inside the filename (`INV_8261_final.pdf`).

### Step 3: Run `List Scanner.exe` & Select Mode
Double-click **`List Scanner.exe`**.

1. The engine will open in a maximized console window and display the **Matching Mode Selection Menu**:
   - **`[1] ALL MODES (Default - Press Enter)`**: Scans for exact filenames, base names, and embedded substrings.
   - **`[2] Full Filename with Extension Only`**
   - **`[3] BaseName without Extension Only`**
   - **`[4] Embedded Substring / Partial ID Only`**
2. Press **Enter** (or type `1` to `4` and hit Enter).
3. The engine creates a timestamped output directory: `List Items (dd-MM-yyyy - HH.mm.ss)`.
4. Copies all matched files and performs post-copy file size verification.
5. Generates detailed report logs inside `List Items (...)/Reports/`.

---

## 🛠️ How to Build from Source

If you modify `src/M3 File Engine.ps1` or update `assets/icon.png`, you can re-compile `List Scanner.exe` with a single command using Windows' built-in C# compiler (`csc.exe`):

Open PowerShell in the repository root and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "build/Build-Exe.ps1"
```

The build script will:
1. Generate `assets/icon.ico` from `assets/icon.png`.
2. Embed the script into a C# host template with full Win32 assembly metadata.
3. Compile a new standalone `List Scanner.exe` in the root folder.

---

## 👤 Author & License

Created by **Meet Mistry**.

Distributed under the **MIT License**. See `LICENSE` for details.
