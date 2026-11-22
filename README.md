# Banoi Together

Banoi Together is an experimental co-op enhancement mod for **Dead Island: Definitive Edition on Steam** (app 383150). The package/project identifier is `DIDE-CoopQuestActivity`.

The long-term goal is to make playing through the campaign with friends feel more like a shared experience: better quest coordination, shared quest conversations, independent dialogue skipping, and other co-op quality-of-life improvements. The current work is limited to quest acceptance through ordinary chat.

**Development status and agent handoff: [PROGRESS.md](https://github.com/caffeineLover/Banoi-Together/blob/main/PROGRESS.md).** This is the single record of verified results, failures, native evidence, build identities and next steps. Future agents should read it first and update/push it with each meaningful work step.

## Current test result

**Diagnostic 3 / `v0.1.0-test.2` uses the exact DLL that passed one local acceptance-to-chat test on Client A.** Peter accepted **The Lost**, and the game displayed the automatic message with normal **Phaedruss** sender attribution. The log confirms native quest ID 372, the copied displayed title `THE LOST`, the committed local offer phase, and one ordinary chat send with body `accepted "THE LOST"`. The mod does not prepend a name.

**Remote delivery is still untested for this corrected build. Completion announcements are disabled.** Unsupported or unconfirmed paths send nothing. General duplicate handling and other acceptance paths still need testing. This is not the finished v0.1 mod.

This DLL is already installed on Peter's laptop (**always Client A**). Its SHA-256, also required inside the release ZIP and on B, is:

```text
761A3124AC68F1DCC1AB8312BA5102E8046D5F9F708BF9A7F0708AEC158E4E87
```

No reinstall or repeat local quest acceptance is needed on A when its installed DLL matches this hash. Any different DLL, including a CI rebuild from the same source, requires a fresh local acceptance-to-chat test on A before installing it on B. **Use the Release asset below for this test, not an Actions build artifact.**

## Installation and release availability

Use **[v0.1.0-test.2](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.2)** for the remote-acceptance test. The older `v0.1.0-test.1` skipped the delayed acceptance path used by Passport to Life; installing it again does not install this correction.

For the next coordinated test, A and B must use the same corrected package; C installs nothing. An observer is required on each player whose own actions should be announced. Ordinary recipients are intended to remain unmodified, pending the vanilla-receiver test.

1. Download [DIDE-CoopQuestActivity-v0.1.0-test.2.zip](https://github.com/caffeineLover/Banoi-Together/releases/download/v0.1.0-test.2/DIDE-CoopQuestActivity-v0.1.0-test.2.zip) from the [test prerelease](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.2). Use the same Release ZIP on A and B; A may keep its already-installed matching DLL. The repository's automatically generated **Source code** ZIP is not an installable package.
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

Find `DIDEQuestChatPoC.log` in the game's Windows temporary directory (usually `%TEMP%`; an inherited `TMP` can change it). Require a fresh `READY diagnostic 3` line on A and B. The old test.1 reports diagnostic 2. The startup log distinguishes successful hook installation from an unsupported build. `SUCCESS` from the installer proves installation, not quest/chat functionality.

## Remote acceptance test

1. **A and B modded, C completely vanilla.** With B's game closed, install the test.2 Release ZIP. On A/B compare the installed `xinput1_3.dll` hash against the value above and the ZIP's `version.json`. Require `READY diagnostic 3` after each launches. A hosts the initial session; record the host and player display names. Do not accept a quest yet.
2. Send distinct ordinary messages: `A manual test`, `B manual test`, `C manual test`. Peter opens chat with **C** and presses **Enter** to send; other players use their configured key. Confirm A's message is visible on B/C, B's on A/C, and C's on A/B. A message being sent is not enough; stop if a recipient cannot see it.
3. A accepts **one naturally available NPC quest**, notes the exact displayed title, and lets the conversation finish. Do not type the expected automatic message. B and C each report the body, sender and count; require exactly one `accepted "<displayed title>"` from A. Check promptly because ordinary chat has limited visibility.
4. After recording A's result, B accepts a different naturally available quest. Require exactly one matching message from B on A and C. An already accepted quest cannot repeat the probe; do not reset or force quest state.
5. Preserve A's and B's complete current-run logs before another test, plus each receiver's observations and approximate time. C needs no mod or observer log. Record results in [PROGRESS.md](https://github.com/caffeineLover/Banoi-Together/blob/main/PROGRESS.md#remote-acceptance-test-record). A stock sender return alone does not prove remote receipt.

Stop at the first failed boundary: **confirmed local acceptance -> quest ID -> copied displayed title -> ordinary chat send -> remote receipt**. Do not add completion announcements or change networking/HUD while running this test. After both directions pass, continue with the remaining acceptance controls separately.

To compare a DLL in PowerShell, use `Get-FileHash -Algorithm SHA256 -LiteralPath 'C:\Program Files (x86)\Steam\steamapps\common\DIDE\xinput1_3.dll'`, adjusting the game path if needed. The expected hash is printed above; installation location may vary by Steam library.

## Build and test

Developers need Windows and MSVC x64 C++ build tools; installed game files are not needed to build or run fixture tests. The forwarding smoke test also needs system XInput 1.3 from Microsoft's [legacy DirectX runtime](https://www.microsoft.com/en-us/download/details.aspx?id=8109), normally already installed on a PC running this game. CI installs that dependency only on its temporary runner; it is not bundled in the ZIP.

```bat
poc\build.cmd
tests\Acceptance.Tests.cmd
research\smoke_test.cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Installer.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Package.Tests.ps1
```

The packaging test creates the ZIP under `dist/`, checks its curated contents and hashes, and exercises installation/uninstallation with temporary fake Steam/game fixtures. It does not install into your real game.

## GitHub test builds

The **Test build and release** Actions workflow compiles/tests/packages pushes, pull requests and manual runs. Its downloadable `test-package` artifact contains the installable ZIP and checksum. A passing CI run does not replace the live Client A test.

Normally test tags prepare a **draft prerelease** from CI; branch/PR/manual builds never publish a Release. **`v0.1.0-test.2` is an explicit exception:** its Release ZIP is packaged from the existing A-tested DLL, with refreshed README/version metadata, and uploaded separately. CI checks this tag but skips automatic release upload so its rebuilt DLL cannot replace the tested payload. Actions artifacts may contain a different DLL and are not the A-validated Release asset. This prerelease does not establish multiplayer delivery or completion support.

Only this project's original source, scripts, documentation and compiled observer are included. Game assets and game/system DLLs are not distributed. The proxy forwards the three imported XInput functions to Windows' existing system DLL. Project source is MIT licensed; that license does not apply to the game or Microsoft runtime code.
