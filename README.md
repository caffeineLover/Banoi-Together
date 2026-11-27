# Banoi Together — test.4

Co-op quest messages for Dead Island: Definitive Edition on Steam.

## Install

1. Close the game and extract the entire installer ZIP.
2. Double-click **Setup Banoi Together.cmd**. Keep the **Support - Do Not Run** folder alongside it.
3. Choose **1. Install or upgrade**, then **A** for Peter or **B** for Hannah. Wait for **Setup complete**. Morty stays vanilla.
4. Start the game through Steam. Your Desktop log is `DIDEQuestChatPoC-A.log` or `DIDEQuestChatPoC-B.log`. Check that the latest startup says `READY diagnostic 5`.

To uninstall, close the game and choose **2. Uninstall** from the same launcher.

## Playtest

- **Quest chat.** In the same session, A and B each accept and later turn in a fresh NPC quest. The other two players watch for one correctly titled `accepted` and `completed` message from the player who acted. Completion is experimental.
- **Native dialogue.** Turn on subtitles and stand near the NPC while one player talks. Have Morty report separately whether he heard the NPC's voice and saw the subtitles, who got the choices, and whether his quest changed. This checks what the game shares natively.
- **Host swap and rejoin.** Switch hosts or rejoin during normal play. Watch for old announcements replaying. After a host change, accept a fresh quest if you're testing its completion.

Report the quest title, who acted, and what each player saw or heard. If something fails, include the approximate time and the acting player's Desktop log.

[Development notes and previous results](https://github.com/caffeineLover/Banoi-Together/blob/main/PROGRESS.md)
