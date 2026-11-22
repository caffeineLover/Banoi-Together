# Banoi Together test build

Installable diagnostic for Steam Dead Island: Definitive Edition (app 383150). Use the same ZIP on A and B; leave C completely vanilla. Extract all files and run `Install.cmd`. Installation locates Steam libraries, checks the supported native binaries and refuses conflicting proxies. `Uninstall.cmd` removes only the matching owned files. No original game file or PAK is modified.

Acceptance announcements use normal player chat for the supported, confirmed local acceptance path. **Completion announcements are disabled**; finish/talk callbacks are diagnostic logging only. General duplicate suppression and multiplayer success are not yet established.

The ZIP includes the compiled proxy, install/uninstall scripts and wrappers, metadata, README and license. No development environment is required on B, and no game or system DLLs are included.

This Release is created as a **draft prerelease**. Keep it unpublished until Client A's local acceptance-to-chat path is verified. Then install this exact CI-produced ZIP on A and B for the A/B/C test matrix. CI success and installer success do not prove native quest semantics or remote delivery.
