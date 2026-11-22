# Banoi Together

An experimental quest-activity observer for **Dead Island: Definitive Edition on Steam** (app 383150). The package/project identifier is `DIDE-CoopQuestActivity`.

**Current test build:** attempts `accepted "Quest Title"` through ordinary player chat for one traced acceptance path. The game supplies the sender's name. Completion announcements are **disabled**; turn-ins currently produce diagnostic logs only. Unsupported acceptance paths send nothing. Multiplayer delivery and complete duplicate suppression are still unverified. This is not the finished v0.1 mod.

## Install on A and B

1. Download [DIDE-CoopQuestActivity-v0.1.0-test.1.zip](https://github.com/caffeineLover/Banoi-Together/releases/download/v0.1.0-test.1/DIDE-CoopQuestActivity-v0.1.0-test.1.zip) from the [test prerelease](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.1). Use the same ZIP on both PCs. The repository's automatically generated **Source code** ZIP is not an installable package.
2. Exit the game and extract **all** files into a folder.
3. Double-click `Install.cmd`. Approve Windows' administrator prompt if required. Require a final `SUCCESS` message. No compiler, SDK, external loader or separate Visual C++ runtime installation is needed on B.
4. Launch normally through Steam. Install nothing on **C**, the vanilla receiver/control.

The installer searches Steam's registered location and library list, verifies the x64 executable and both supported native DLL fingerprints, and installs only `xinput1_3.dll` plus its ownership receipt. A temporary recovery journal restores the previous installation if a write fails; rerun install/uninstall after an interrupted process to recover. It refuses another mod's proxy and upgrades only a matching owned/known build. It never writes any original game file, including `Data0.pak`, `Data1.pak` or `Data2.pak`.

If discovery finds multiple installations, or none, open PowerShell in the extracted folder:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -GamePath "D:\SteamLibrary\steamapps\common\DIDE"
```

Use `-WhatIf` for validation without installing. `-SteamPath` can specify a nonstandard Steam root. Wrong native hashes mean this exact test build is unsupported; do not replace original game DLLs to bypass that check. A filesystem link/junction in the selected path is currently refused.

## Uninstall

Exit the game and double-click `Uninstall.cmd` from the extracted package, or run `Uninstall.ps1`. The same `-GamePath` and `-SteamPath` options are available. Only the matching owned DLL and receipt are removed. An unknown or modified DLL is left untouched.

## Check readiness and report a result

Find `DIDEQuestChatPoC.log` in the game's Windows temporary directory (usually `%TEMP%`; an inherited `TMP` can change it). Require a fresh `READY diagnostic 2` line on A and B. The startup log distinguishes successful hook installation from an unsupported build. `SUCCESS` from the installer proves installation, not quest/chat functionality.

Verify normal manual chat on A/B/C, then accept one naturally available quest on A. Record the displayed title and whether B/C saw one correctly attributed automatic message. Repeat with B acting. Current completion tests collect logs, without sending `completed` chat. Load/rejoin and actions by vanilla C must not cause automatic announcements. See the repository's [test checklist](https://github.com/caffeineLover/Banoi-Together/blob/main/ACTIVITY_TESTING.txt) and [native trace](https://github.com/caffeineLover/Banoi-Together/blob/main/ACTIVITY_TRACE.txt).

## Build and test

Developers need Windows and MSVC x64 C++ build tools; installed game files are not needed to build or run fixture tests. The forwarding smoke test also needs system XInput 1.3 from Microsoft's [legacy DirectX runtime](https://www.microsoft.com/en-us/download/details.aspx?id=8109), normally already installed on a PC running this game. CI installs that dependency only on its temporary runner; it is not bundled in the ZIP.

```bat
poc\build.cmd
research\smoke_test.cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Installer.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Package.Tests.ps1
```

The packaging test creates the ZIP under `dist/`, checks its curated contents and hashes, and exercises installation/uninstallation with temporary fake Steam/game fixtures. It does not install into your real game.

## GitHub test builds

The **Test build and release** Actions workflow compiles/tests/packages pushes, pull requests and manual runs. Its downloadable `test-package` artifact contains the installable ZIP and checksum. A passing CI run does not replace the live Client A test.

Tags such as `v0.1.0-test.1` also prepare a **draft prerelease** containing that exact CI-built ZIP. Publishing the prepared draft is a separate step; branch/PR/manual builds never publish a Release. The first prerelease is published at the user's request so B can install for testing, before live quest/chat validation. Install that same Release ZIP on A/B; the checksum in `version.json` identifies the DLL. This diagnostic prerelease does not establish that acceptance, completion or multiplayer delivery works.

Only this project's original source, scripts, documentation and compiled observer are included. Game assets and game/system DLLs are not distributed. The proxy forwards the three imported XInput functions to Windows' existing system DLL. Project source is MIT licensed; that license does not apply to the game or Microsoft runtime code.
