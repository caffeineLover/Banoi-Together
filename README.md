# Banoi Together

Banoi Together is an experimental co-op enhancement mod for **Dead Island: Definitive Edition on Steam** (app 383150). The package/project identifier is `DIDE-CoopQuestActivity`.

The long-term goal is to make playing through the campaign with friends feel more like a shared experience: better quest coordination, shared quest conversations, independent dialogue skipping, and other co-op quality-of-life improvements. The current work is limited to quest acceptance through ordinary chat.

**Development status and agent handoff: [PROGRESS.md](https://github.com/caffeineLover/Banoi-Together/blob/main/PROGRESS.md).** This is the single record of verified results, failures, native evidence, build identities and next steps. Future agents should read it first and update/push it with each meaningful work step.

## Current test result

Diagnostic 3 passed two-way remote quest acceptance with A and B modded and Morty (C) vanilla. A's EXODUS announcement reached B/C, and B's LAZARUS RISING announcement reached A/C.

## Test.3 setup and turn-in capture

1. Close the game, extract the whole test.3 ZIP and double-click **`Setup Banoi Together.cmd`**. Choose **1. Install or upgrade**, then enter **A** for Peter or **B** for Hannah. Approve the Windows prompt if asked and wait for **Setup complete**. Leave the `Support - Do Not Run` folder alongside the launcher. C installs nothing.
2. Launch from Steam under the same Windows account you used for setup. Open `DIDEQuestChatPoC-A.log` or `DIDEQuestChatPoC-B.log` on your Desktop. Check the newest startup line for `tester=A` or `tester=B` and `log=Desktop`, then `READY diagnostic 4`. If no Desktop log appears, check `%TEMP%` for the same filename and report the fallback.
3. Validate test.3 on A first. Accept a fresh NPC quest and confirm one correctly titled acceptance line in local chat. At a natural quest turn-in, note the exact displayed title and local time, complete the turn-in as usual, and preserve the Desktop log. Report what changed in the game or quest journal. Completion is trace-only in test.3.

To uninstall test.3, close the game, open the same launcher, choose **2. Uninstall**, and confirm. For a custom game directory, you can run `& '.\Setup Banoi Together.cmd' -GamePath 'D:\SteamLibrary\steamapps\common\DIDE'` from the extracted folder in PowerShell.

## Published test.2 reference

**Diagnostic 3 / `v0.1.0-test.2` uses the exact DLL that passed one local acceptance-to-chat test on Client A.** Peter accepted **The Lost**, and the game displayed the automatic message with normal **Phaedruss** sender attribution. The log confirms native quest ID 372, the copied displayed title `THE LOST`, the committed local offer phase, and one ordinary chat send with body `accepted "THE LOST"`. The mod does not prepend a name.

**Remote acceptance delivery passed in both directions. Completion announcements are disabled.** Unsupported or unconfirmed paths send nothing. General duplicate handling and other acceptance paths still need testing.

This DLL is already installed on Peter's laptop (**always Client A**). Its SHA-256, also required inside the release ZIP and on B, is:

```text
761A3124AC68F1DCC1AB8312BA5102E8046D5F9F708BF9A7F0708AEC158E4E87
```

No reinstall or additional **solo validation** is needed on A when its installed DLL matches this hash. **A must still accept a new NPC quest during the multiplayer test below so B and C can check its automatic announcement.** Any different DLL, including a CI rebuild from the same source, requires a fresh local acceptance-to-chat test on A before installing it on B. **Use the Release asset below for this test, not an Actions build artifact.**

## Installation and release availability

Use **[v0.1.0-test.2](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.2)** for the remote-acceptance test. The older `v0.1.0-test.1` skipped the delayed acceptance path used by Passport to Life; installing it again does not install this correction.

For the next coordinated test, A and B must use the same corrected package; C installs nothing. An observer is required on each player whose own actions should be announced. Ordinary recipients are intended to remain unmodified, pending the vanilla-receiver test.

1. Download [DIDE-CoopQuestActivity-v0.1.0-test.2.zip](https://github.com/caffeineLover/Banoi-Together/releases/download/v0.1.0-test.2/DIDE-CoopQuestActivity-v0.1.0-test.2.zip) from the [test prerelease](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.2). Use the same Release ZIP on A and B; A may keep its already-installed matching DLL. The repository's automatically generated **Source code** ZIP is not an installable package.
2. Exit the game and extract **all** files into a folder.
3. In the published test.2 ZIP, double-click `Install.cmd`. Approve Windows' administrator prompt if required and wait for `SUCCESS`.
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

**This test requires actually accepting NPC quest offers. Typing a chat message is only the preliminary connectivity check. Opening the quest journal, selecting an existing quest, or typing an acceptance announcement does not test the mod.**

1. **Prepare the three PCs.** Peter is A and already has the exact tested DLL installed. B closes the game, downloads the [test.2 Release ZIP](https://github.com/caffeineLover/Banoi-Together/releases/download/v0.1.0-test.2/DIDE-CoopQuestActivity-v0.1.0-test.2.zip), extracts all files, double-clicks `Install.cmd` from that extracted folder and requires `SUCCESS`. C installs nothing and stays completely vanilla. Use the Release ZIP, not test.1, Source code or an Actions artifact.
2. **Confirm the build before spending a quest.** The installed DLL on A and B must match the full SHA-256 printed above and the release's `version.json`; the PowerShell command below checks it. A's installed hash was already verified against the downloaded release. If either DLL differs, stop: a different payload needs a new successful solo acceptance test on A before installation on B.
3. **Start the co-op session.** Launch normally through Steam. A hosts/loads the save; B and C join A. Confirm all three are in the same session and note their displayed player names. On A and B check the latest startup block in `%TEMP%\DIDEQuestChatPoC.log` for `READY diagnostic 3`; an old run's line or diagnostic 2 is insufficient. Stop if startup failed. Nobody accepts or turns in a quest during setup.
4. **Check manual chat, one sender at a time.** A presses **C**, types `A manual test`, then presses **Enter**; B and C each confirm they saw it attributed to A. B uses their configured chat key to send `B manual test`; A and C each confirm receipt. C sends `C manual test`; A and B each confirm receipt. Record actual recipient visibility, not just that each sender pressed Enter. Stop if any message is missing. This step alone is not the quest test.
5. **Prepare A's real quest offer.** Find a naturally available NPC quest that A has not already accepted. The Lost cannot be repeated if it is already accepted. A opens the NPC's offer and notes its exact displayed quest title. Tell B and C to watch their normal chat/HUD; all players hold off on other quest actions and additional manual chat so the automatic line is easy to spot.
6. **A selects Accept on the NPC's quest offer.** Let the NPC conversation finish and normal gameplay resume. Do not manually type `accepted ...` or prepend a player name. Accepting the quest must cause the mod to send the message automatically after its confirmed state change.
7. **Record A's result before continuing.** A notes whether the automatic line appeared locally. B and C independently report the displayed sender, quest title and number of automatic lines. Each must receive exactly one ordinary chat announcement attributed to A, with body `accepted "<A's displayed quest title>"`. The game's normal presentation/capitalization may differ. Record the approximate time immediately because chat visibility is brief. If the line is missing, duplicated or incorrect, stop quest testing and preserve the logs instead of accepting more quests.
8. **Repeat with B doing the actual acceptance.** Only after A's result is recorded and passes, B finds a different naturally available, not-yet-accepted NPC quest and notes its displayed title. A and C watch normal chat. B selects **Accept** on that NPC offer and lets the conversation finish, without typing an announcement. B notes local display; A and C each must receive exactly one automatic `accepted "<B's displayed quest title>"` message attributed normally to B. Record the title, sender, count and approximate time. Stop on a missing, duplicate or wrong line.
9. **Preserve evidence on both modded PCs.** Copy A's and B's complete `DIDEQuestChatPoC.log` from their Windows temporary directories before another launch/test. To find it, press Win+R, enter `%TEMP%`, and locate that filename. Keep separate copies named, for example, `A-test2-remote.log` and `B-test2-remote.log` on the Desktop. They can quit normally first; do not delete the original logs. C only needs to report what appeared, since C has no mod log. If the log is absent, report that rather than reinstalling or changing game files.
10. **Report both probes.** For A's acceptance provide the quest title, approximate time, what A saw locally, and what B/C saw including sender and count. For B's acceptance provide the corresponding B-local and A/C observations. Supply the preserved logs when requested. Record the results in [PROGRESS.md](https://github.com/caffeineLover/Banoi-Together/blob/main/PROGRESS.md#remote-acceptance-test-record). Both directions must pass before moving on; do not test turn-ins/completion or other acceptance cases yet.

Stop at the first failed boundary: **confirmed local acceptance -> quest ID -> copied displayed title -> ordinary chat send -> remote receipt**. Do not add completion announcements or change networking/HUD while running this test. After both directions pass, continue with the remaining acceptance controls separately.

To compare the installed DLL in PowerShell, run this on A/B, adjusting the game path if Steam uses another library:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath 'C:\Program Files (x86)\Steam\steamapps\common\DIDE\xinput1_3.dll'
```

The expected hash is `761A3124AC68F1DCC1AB8312BA5102E8046D5F9F708BF9A7F0708AEC158E4E87`. To inspect startup, open the log in Notepad and scroll to the latest startup block; check the run just launched, not a previous READY line. An inherited `TMP` can put the log elsewhere; report a missing log so its actual location can be checked.

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
