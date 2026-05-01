# AGENTS.md — ElevenClock

Guidance for AI coding agents working in this repository. Keep changes minimal, Windows-aware, and respect the existing structure.

## What this project is

ElevenClock is a Windows 11 desktop utility (Apache 2.0) that places customizable clocks on the taskbar(s) of every connected display. It is a PySide6 (Qt for Python) application packaged with PyInstaller and distributed via an Inno Setup installer, the Microsoft Store, Winget and Chocolatey.

- Upstream: `martinet101/ElevenClock` (homepage: https://www.marticliment.com/elevenclock/)
- Current version: see `elevenclock/versions.py` (4.4.1.1 at time of writing)
- License: Apache License 2.0

## Repository layout

```
elevenclock/                Main Python package (application source)
  __init__.py               Application entry point / main loop
  settings.py               Settings window
  tools.py                  Shared helpers, translator function `_`
  globals.py                Module-level shared state (e.g. clocks list)
  versions.py               version, versionName, versionISS constants
  welcome.py                First-run welcome wizard
  elevenclock.spec          PyInstaller spec consumed by build.cmd
  data/                     Auto-generated data (contributors, translations metadata)
  external/                 Vendored helpers (FramelessWindow, blurwindow, WnfReader, timezones...)
  lang/                     Per-language JSON files (lang_xx.json) used at runtime
  resources/                Icons, images, sounds, QSS
scripts/                    Maintenance scripts (Python)
  apply_versions.py         Stamps version into installer/version-info files
  check_python_version.py   Enforces a minimum Python version during build
  download_translations.py  Pulls translations from Tolgee
  generate_release.py       Release artifact / GitHub release helper
  get_contributors.py       Refreshes contributors data
  purge_unusedtranslations.py / verify_translations.py / translation_*.py
build.cmd                   Local full build: requirements + compile + PyInstaller + Inno Setup
build_noinstaller.cmd       Local build without producing the installer
build_release.cmd           Local release-mode build wrapper
build_ci.cmd                Non-interactive build script used by GitHub Actions (arch-agnostic;
                            the runner determines x64 vs ARM64). No pauses, no signing prompts,
                            no Inno Setup invocation — installers are built by the workflow.
ElevenClock.iss             Inno Setup installer script (consumed locally and by CI)
elevenclock-version-info    PyInstaller version info template
requirements.txt            Runtime/build Python dependencies
requirements_install.cmd    Convenience installer for requirements
.github/workflows/          CI: health check (compileall), CodeQL, lang updates,
                            translations test, winget release, build-x64, build-arm64
media/, misc/, icon.*       Marketing assets and icons
TRANSLATION.md              Notes on translating (see also wiki link in README)
```

## Setup

Prerequisites:

- Windows 10/11 (this app is Windows-only; many imports rely on `win32gui`, `windll`, `winshell`, `win32mica`, etc. — do not try to run on Linux/macOS).
- Python **3.11+** (`scripts/check_python_version.py` enforces `>=3.11.0`).
- Inno Setup 6 at `C:\Program Files (x86)\Inno Setup 6\ISCC.exe` — only required to build the installer.

Install dependencies (PowerShell):

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Or use the provided helper: `requirements_install.cmd`.

Key dependencies (`requirements.txt`): `PyInstaller>=6.11`, `PySide6>=6.9`, `keyboard`, `psutil`, `pytz`, `win32mica`, `winshell`, `pypiwin32`.

## Running the app from source

```powershell
cd elevenclock
python __init__.py
```

Note: `__init__.py` is the entry point — it is invoked directly, not via `python -m elevenclock`. The build pipeline copies it alongside compiled `.pyc` files in the bundled output.

## Building

- `build.cmd` — full pipeline: installs requirements, runs `apply_versions.py`, copies `elevenclock` → `elevenclock_bin`, byte-compiles, deletes `.py` sources, runs PyInstaller (`elevenclock.spec`), prunes unneeded Qt plugins/DLLs, then invokes Inno Setup to produce `ElevenClock.Installer.exe`.
- `build.cmd --no-installer` — skip the Inno Setup step (and the launcher).
- `build.cmd --only-requirements` — install dependencies only.
- `build.cmd --release` — also runs `scripts/generate_release.py` afterwards.
- `build_noinstaller.cmd` / `build_release.cmd` — thin wrappers around the above.

The build pauses for manual signing of both the EXE and the installer — do not try to automate past those `pause` steps without user consent.

## CI

Workflows live in `.github/workflows/`:

- **Basic health check** — on `**.py` push/PR to `main`: installs deps and runs `python -m compileall -q .` inside `elevenclock/`. There is no test suite.
- **codeql-analysis** — security scanning.
- **lang-updates** — pulls translation updates (uses `scripts/download_translations.py` and Tolgee).
- **translations-test** — validates translation JSON.
- **winget-release** — publishes Winget manifests on release.
- **build-x64** — runs on `windows-latest`. Executes `build_ci.cmd`, installs Inno Setup, runs `ISCC /FElevenClock.Installer.x64 ElevenClock.iss`. Uploads `ElevenClockBin/` and `ElevenClock.Installer.x64.exe` as artifacts; on `release: published` attaches the installer to the GitHub Release.
- **build-arm64** — runs on `windows-11-arm`. Same flow as build-x64 but native ARM64; produces `ElevenClock.Installer.arm64.exe`.

Dependabot config: `.github/dependabot.yml` (cron is every 7 days — see commit `f967218`).

## Conventions for agents

- This is a **Windows-only** codebase. Do not add cross-platform shims or Linux/macOS branches unless asked.
- The shell on the maintainer's environment is **PowerShell**. Build scripts are `.cmd` (batch). Do not introduce Makefiles or Bash-only scripts.
- Use `/` as a path separator in any new code — it works on both Windows shells and Python.
- Translations are managed via Tolgee and the scripts in `scripts/`. Do not hand-edit `lang/lang_*.json` for content changes; only the English source typically changes locally and the rest are synced. The autogenerated translation table in `README.md` is bracketed by `<!-- Autogenerated translations -->` markers — leave it alone unless running the generator.
- `elevenclock/data/contributors.py` and `elevenclock/data/translations.py` are generated — do not edit by hand.
- Bump the version by editing **only** `elevenclock/versions.py`; `apply_versions.py` propagates it to the installer and version-info files at build time.
- Translator function: user-facing strings go through `_()` (imported from `tools`). Keep that pattern when adding strings.
- The app patches `sys.stdout` early in `__init__.py` when frozen and prints log lines with emoji legend markers (🔵 verbose, 🟢 info, etc.). Match that style for new log lines if added.
- There is no formal test suite — the only automated check is `compileall`. Manually verifying a change by running from source is the expected workflow.

## Useful pointers

- Entry point and main loop: `elevenclock/__init__.py`
- Settings UI: `elevenclock/settings.py`
- Shared helpers / i18n: `elevenclock/tools.py`
- PyInstaller config: `elevenclock/elevenclock.spec`
- Installer script: `ElevenClock.iss`
- Version source of truth: `elevenclock/versions.py`
