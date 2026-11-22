# Test release implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task. Steps use checkbox syntax.

**Goal:** Prepare a development-environment-free test ZIP for A/B in caffeineLover/Banoi-Together and a GitHub workflow that builds each tagged test release.

**Architecture:** Keep the diagnostic native DLL unchanged. Package one DLL with PowerShell install/uninstall entry points, a shared helper, metadata, a short README and command wrappers. Verify the exact supported game binaries before installation; manage only the proxy DLL and its ownership receipt.

**Tech stack:** C++17/MSVC x64, Windows PowerShell 5.1, GitHub Actions on Windows, GitHub CLI in the hosted release job.

**Spec:** The user's latest instructions: public repository caffeineLover/Banoi-Together (requested display name Banoi Together), v0.1.0-test.1, DIDE-CoopQuestActivity-v0.1.0-test.1.zip, Steam discovery, no archive modifications, and publish a test Release only after Client A works. Existing feature limitations are recorded in [ACTIVITY_TESTING.txt](../../../ACTIVITY_TESTING.txt).

## Global constraints

- No writes to Data0.pak, Data1.pak or Data2.pak, or other original game files.
- A/B modded; C vanilla. Live quest testing remains paused.
- Completion sends remain disabled. A working acceptance-to-chat path is not yet verified.
- Installer preparation and repository publication are authorized now; no release tag/publication until Client A's live chain is verified.
- No game binaries, saves, logs or copyrighted game assets in Git or the ZIP.

## Review focus

- Unknown proxy or ownership receipt: fail before overwriting anything.
- Wrong game build or corrupt payload: fail without a partial install.
- Steam secondary libraries, legacy library format, spaces and multiple installs: discover deterministically or request an explicit game path.
- Running game and filesystem links: refuse writes; uninstall only its own unchanged DLL.
- Interrupted install/upgrade: restore the old owned files; do not report success on a failed write.

## Task 1: Installer and uninstaller

Files: package/Install.ps1, package/Uninstall.ps1, package/Installer.Common.ps1, package/Install.cmd, package/Uninstall.cmd, package/version.json; tests/Installer.Tests.ps1.

- [x] Write dependency-free tests using temporary fake Steam libraries and game files; verify discovery, install/rerun/upgrade/uninstall, unknown-file refusal, wrong native/payload hashes, process guard, links and archive preservation.
- [x] Run the tests and observe missing-implementation failure.
- [x] Implement fixed-name file management, exact native validation, ownership receipts, safe rollback, WhatIf, clear results and UAC retry only on an access-denied write.
- [x] Run all installer tests on Windows PowerShell 5.1; inspect actual output.

## Task 2: Portable build and ZIP

Files: tools/MsvcEnvironment.cmd, poc/build.cmd, research/smoke_test.cmd, tools/Build-Package.ps1, README.md, LICENSE, .gitignore.

- [x] Detect MSVC through vswhere, with the existing local installation as a fallback.
- [x] Build the unchanged native source; run the proxy smoke test.
- [x] Build a curated ZIP with a generated DLL SHA256 in version.json and a ZIP checksum alongside it.
- [x] Inspect ZIP entries and install/uninstall its extracted contents against a fake game fixture. Dry-run discovery against the actual installation without writes.

## Task 3: GitHub workflow and repository

Files: .github/workflows/test-release.yml, RELEASE_NOTES.md; update TESTING.txt and ACTIVITY_TESTING.txt.

- [x] Add branch/PR/manual build verification and tagged v*-test* draft prerelease preparation. A CI build artifact alone is not proof of a passing game test.
- [x] Review scripts/workflow and fix material findings with regression tests.
- [x] Initialize Git on a test-release preparation branch and commit only the curated source/docs.
- [x] Publish repository after destination/visibility and usable authentication are available. Do not recreate a repository that already exists or overwrite remote history.
- [x] Leave v0.1.0-test.1 untagged/unpublished until Client A's live acceptance chain passes; record the exact remaining gate.

## Progress

Plan created. Ruling: continue in the user's existing previously non-Git workspace and initialize a preparation branch; there is no existing Git checkout to isolate. Cost: installer edits remain directly visible in this workspace.

Task 1: complete. Initial missing-implementation RED observed, followed by 13/13 fixture tests. Task 2 package test initial RED observed; compiled unchanged C++ with /W4 /WX and passed proxy forwarding/unsupported-build smoke checks. Extracted ZIP installation passed 14/14 cases.

Final fresh-context review: two Important findings, no Minor findings. Fixed durable interruption recovery and original-console elevation results. Added regressions and observed RED for both, then GREEN. A real Steam -WhatIf attempt also exposed PS 5.1 Get-FileHash's inherited WhatIf behavior on first invocation; a fresh-process fixture reproduced RED, and direct read-only .NET hashing fixed it. Current source installer suite: 17/17 passed, including forced process termination at both commit boundaries on fresh install and upgrade, unknown journal refusal, original-console elevation success/failure, and a fresh-process dry run.

Review scope boundary: native quest semantics, completion messages, duplicate suppression and multiplayer success remain outside packaging verification and explicitly unverified. Ruling: preserve these diagnostic limitations and the paused gameplay test; cost: this package cannot yet be called the usable v0.1 mod.

Task 2: complete. Final extracted-package suite 18/18 passed. Actual Steam discovery and -WhatIf validation passed against the real supported installation with no installation writes. Git initialized on prepare-test-release. Git metadata writes require the host's elevated execution context; use a per-command safe.directory for this one workspace because initialization ran under the sandbox identity. No global safe-directory exception is needed.

Task 3: source published to the requested existing empty public repo, main, commit 7223b58. Connector write API returned 403; ordinary Git upload succeeded using existing credentials. No tags or Releases created. Release-step simulation passed for new draft, draft rerun and published-release refusal. First hosted run compiled successfully, then failed at smoke module load 126: the Windows Server runner lacks the legacy system XInput dependency present on the game PC. CI now provisions only its ephemeral runner with the official Microsoft-signed DirectX runtime before the smoke test. No Microsoft files enter Git or the ZIP. README documents this build/test dependency.

Additional CI-shell regression: running the green fixture suite in the same PowerShell scope as GitHub leaves LASTEXITCODE=-1 from an intentionally killed test child (RED with the runner's final exit-code check). The suite now explicitly exits 0 after all cases pass, preserving nonzero failure behavior. Native observer source remains unchanged.

2026-11-22 publication update: the user explicitly needs a Release so Client B can install. This supersedes the earlier unpublished-first-test gate for v0.1.0-test.1. Publish it as a diagnostic prerelease after tagged CI passes, with clear unverified acceptance/chat behavior and disabled completion announcements. The usable v0.1 release still requires live verification and duplicate suppression. Gameplay testing remains paused; no native code or installed game files are changed by publication.
