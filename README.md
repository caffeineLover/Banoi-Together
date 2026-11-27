# Banoi Together — test.6

Co-op quest messages and a fullscreen shortcut for Dead Island: Definitive Edition on Steam.

Test.6 fixes the setup error some players saw after choosing their player letter in test.5.

## Install

1. Close the game and extract the entire installer ZIP.
2. Double-click **Setup Banoi Together.cmd**. Keep the **Support - Do Not Run** folder alongside it.
3. Choose **1. Install or upgrade**, then **P** for Peter, **H** for Hannah, or **M** for Morty. Wait for **Setup complete**.
4. Start through Steam. Each launch creates a new log on your Desktop with your name and the UTC start time. Open the newest one and look for `READY diagnostic 6`.

To uninstall, close the game and choose **2. Uninstall** from the same launcher.

## Fullscreen shortcut

Set the game's video mode to **Windowed** once. Press **F11** to switch to borderless fullscreen and back. To change the key, open `BanoiTogether.yaml` on your Desktop in Notepad, edit `fullscreen_key: F11`, and relaunch the game. Use F1–F24, one letter, or one digit.

## Playtest

- **Quest chat.** In the same session, accept and later turn in a fresh NPC quest. Peers watch for one correctly titled `accepted` and `completed` message. Completion is experimental.
- **Native dialogue.** With subtitles on, check audio and subtitles near the NPC, both in gameplay and with a menu open. For a vanilla comparison, Morty can leave the mod uninstalled and report what he sees and hears. Only installed players get a mod log.
- **Host swap and rejoin.** Switch hosts or rejoin during normal play. Watch for old announcements replaying. After a host change, accept a fresh quest if you're testing its completion.

Report the quest title, who acted, and what each player saw or heard. If something fails, include the approximate time and the acting player's Desktop log.

[Development notes and previous results](https://github.com/caffeineLover/Banoi-Together/blob/main/PROGRESS.md)
