# Banoi Together

Banoi Together is an experimental co-op enhancement mod for Dead Island: Definitive Edition.

The long-term goal is to make playing through the campaign with friends feel more like a shared experience: better quest coordination, shared quest conversations, independent dialogue skipping, and other co-op quality-of-life improvements.

The project is still very early. The current build is primarily a multiplayer test of the first piece of that framework.


## Current test build
The current test build watches for a player accepting a quest and attempts to announce it through Dead Island's normal multiplayer chat:

accepted "Quest Title"

Dead Island supplies the player's name, so other players should see who accepted the quest without Banoi Together having to implement its own networking or notification system.

At the moment:
- Quest acceptance is implemented for one known acceptance path.
- Quest completion/turn-in is logged for testing but is not announced yet.
- Some quest types may not produce a message.
- Multiplayer delivery and duplicate handling still need real-world testing.
This is a test build, not a finished v0.1 release.



## Installation
1. Download Banoi-Together-v0.1.0-test.1.zip from the latest test release. Do not download GitHub's automatically generated “Source code” ZIP.
2. Exit Dead Island.
3. Extract the ZIP somewhere convenient.
4. Double-click Install.cmd.
5. Make sure the installer finishes with SUCCESS.
6. Launch Dead Island normally through Steam.
The installer finds your Steam installation automatically and does not modify Data0.pak, Data1.pak, Data2.pak, or any other original game file.

If automatic detection fails, see Manual installation / troubleshooting.
Testing
For the current multiplayer test, install Banoi Together on at least one player who will accept quests. Other players can remain completely unmodded.

Before testing quest announcements, make sure ordinary Dead Island text chat works between the players.

Then have a modded player accept a normal quest and check whether the other players receive a message such as:

Phaedruss: accepted "Exodus"

If something doesn't work, see [ACTIVITY_TESTING.txt] for the diagnostic checklist and log-file instructions.



## Uninstall
Exit the game and run Uninstall.cmd.

The uninstaller removes only the files installed by Banoi Together.



For developers
and put the native hashes, XInput forwarding, MSVC requirements, CI packaging, smoke tests, release workflow, -WhatIf, test fixtures, etc. down there.

One more thing I would definitely change: rename the distributable from DIDE-CoopQuestActivity-v0.1.0-test.1.zip to Banoi-Together-v0.1.0-test.1.zip. DIDE-CoopQuestActivity is an implementation-era name that has already outlived its usefulness. The mod is Banoi Together now.

So: the current README is good engineering documentation, but poor front-door documentation. I would preserve most of the information, but demote about half of it to developer/testing docs and make the README explain the mod to a person first.


Only this project's original source, scripts, documentation and compiled observer are included. Game assets and game/system DLLs are not distributed. The proxy forwards the three imported XInput functions to Windows' existing system DLL. Project source is MIT licensed; that license does not apply to the game or Microsoft runtime code.
