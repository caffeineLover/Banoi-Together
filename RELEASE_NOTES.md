# Banoi Together v0.1.0-test.1

Installable diagnostic for Steam Dead Island: Definitive Edition (app 383150). Use the same ZIP on A and B; leave C completely vanilla. Extract all files and run `Install.cmd`. Installation locates Steam libraries, checks the supported native binaries and refuses conflicting proxies. `Uninstall.cmd` removes only the matching owned files. No original game file or PAK is modified.

**Diagnostic test build:** acceptance announcements are attempted through one statically traced local acceptance path using normal player chat. The local quest-to-chat chain and delivery to a vanilla co-op client are still unverified. **Completion announcements are disabled**; finish/talk callbacks are diagnostic logging only. General duplicate suppression is not yet implemented.

The ZIP includes the compiled proxy, install/uninstall scripts and wrappers, metadata, README and license. No development environment is required on B, and no game or system DLLs are included.

Download **DIDE-CoopQuestActivity-v0.1.0-test.1.zip** below, extract all files, close the game, and double-click **Install.cmd**. Require the final **SUCCESS** message. Do not download the automatically generated Source code ZIP for installation. Keep the extracted folder to run **Uninstall.cmd** later.

This **test prerelease** is published so Client B can install before coordinated gameplay testing. Install this exact Release ZIP on both A and B; leave C unmodified. CI and installer success do not prove quest/chat functionality. Gameplay testing remains paused until the players are ready.
