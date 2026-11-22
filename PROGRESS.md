# Banoi Together progress and agent handoff

Last updated: **2026-11-22, America/New_York**. This is the authoritative development record. Read it before changing the mod. Installation and build instructions are in [README.md](./README.md).

## Current result

**Client A's local acceptance-to-chat test passed for The Lost using diagnostic 3 / `0.1.0-test.2`.** Peter accepted the NPC offer and saw a normal chat line attributed to **Phaedruss**. The log independently confirms local ownership, the same dialogue resource, quest `Steffen_Q1` / UID `372`, the copied displayed title `THE LOST`, a committed offer-phase transition, and exactly one stock sender call with `accepted "THE LOST"`.

This proves one local acceptance path. **The active milestone is now remote acceptance delivery in both directions: A -> B/C, then B -> A/C, with C completely vanilla. Remote receipt is untested. Completion announcements remain disabled and no further reverse engineering is requested for this phase.** The child-quest acceptance variant is tested offline but has not passed a live test. General duplicate suppression and the full v0.1 matrix remain outstanding. The successful solo run's log is preserved.

### Keep this record current

- Update this file after every meaningful investigation, code change, build, installation, or gameplay test. Record what worked, what failed, evidence, exact build identity, unresolved questions, and the next smallest step.
- Distinguish native/static findings, fixture tests, user observations, and live log evidence. A sender return or CI success does not prove remote delivery.
- Commit and push the progress update with the corresponding source changes to GitHub at the end of the work step. The user explicitly requests this ongoing handoff. If a push fails, say so and record the outstanding local changes; do not claim GitHub is current.
- Keep only this development document and the installation README. Add findings here rather than creating new trace files, testing checklists, or plan documents. Git history retains superseded notes.
- Preserve edits made by the user or other agents on GitHub; fetch before pushing and merge without force-pushing. Keep published release assets/tags immutable.
- Do not infer authorization for new scope from the long-term ideas below. The immediate acceptance test remains the active development gate.

## Scope and constraints

Project: [caffeineLover/Banoi-Together](https://github.com/caffeineLover/Banoi-Together). Package identifier: `DIDE-CoopQuestActivity`. Steam app `383150`, supported installed build `1837542`.

Peter's laptop is **always Client A**. The eventual test topology is **A modded, B modded, C completely vanilla**. Each observer announces only the action initiated on its own machine. Do not manually prepend a name; ordinary chat supplies sender attribution. Peter opens chat with **C**, types, then presses **Enter** to send.

The requested usable version will send `accepted "Quest Title"` after confirmed local acceptance and `completed "Quest Title"` after confirmed successful local turn-in. It must avoid announcements from loading, replication, automatic activation, or another player's action. Current work is restricted to acceptance; do not start completion until the acceptance chain is proven through a vanilla receiver.

Do not modify or replace `Data0.pak`, `Data1.pak`, `Data2.pak`, other original game files, quest state, progression, dialogue, cameras, NPC behavior, or balance. Do not add custom networking/HUD, shared quest acceptance, objective messages, chat commands, or configuration UI. Do not reset/force quests to manufacture tests. Exit the game normally before installation; never kill it to replace a DLL.

The broader project vision includes better co-op coordination, shared conversations and independent dialogue skipping. These are future ideas, not part of this diagnostic or approved implementation sequence. The chat visibility concern is recorded below and remains separate.

## Builds and installation state

| Build | Status | Important limitation |
| --- | --- | --- |
| Original prototype | Loaded in the game; two hooks initially | No successful quest/chat test from that prototype |
| [`v0.1.0-test.1`](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.1), diagnostic 2 | Published diagnostic prerelease so B could install | Explicitly skips the mode-0 path used by Passport to Life; downloading it again does not install the correction |
| [`v0.1.0-test.2`](https://github.com/caffeineLover/Banoi-Together/releases/tag/v0.1.0-test.2), diagnostic 3 | Published; public download contains the exact DLL that passed The Lost on A | B's corrected installation and remote delivery are unverified |

**Tested/installed diagnostic-3 DLL SHA256:**

```text
761A3124AC68F1DCC1AB8312BA5102E8046D5F9F708BF9A7F0708AEC158E4E87
```

Original local test.2 ZIP SHA256, **before refreshing the README for the remote test**:

```text
C9EAE75B12A27664440F95C340EBE5279D53EE2B7C3675D6A1ECDA9B42D4A1A6
```

Release preparation refreshed the README and package version metadata without recompiling or changing the DLL. The release ZIP is `dist/DIDE-CoopQuestActivity-v0.1.0-test.2.zip`; its final checksum and public-download verification are recorded below. The installer implementation is unchanged. Package metadata hashes the native `.cpp` but currently omits the new header; use the DLL hash to identify the tested payload. The source comment pointing to documentation was updated after the live test; acceptance logic was unchanged by consolidation.

The agent installed test.2 on A with the game closed using the packaged installer, then independently compared the installed DLL hash and ownership receipt version. **No further installer action is needed on A for this tested payload.** Real game directory: `C:\Program Files (x86)\Steam\steamapps\common\DIDE`. Fresh gameplay log: `C:\Users\Peter\AppData\Local\Temp\DIDEQuestChatPoC.log`.

The published test.1 DLL hash is `949C2CC09FBF2E27561C75C8987FC36784F63DF2BE32696D4044272C17BA2FED`; its ZIP hash is `78ED8DB94393CC00A2E87EC39824947267A75955347F607A026A3CA71186D928`. Published tagged source commit: `184cdf81f8ae7864a96575364a5210fa7431fde5`. Its passing CI run is [45037125429](https://github.com/caffeineLover/Banoi-Together/actions/runs/45037125429). An older local test.1 ZIP was rebuilt independently: it is not necessarily the published CI asset.

Do not call a freshly compiled CI DLL the exact A-tested binary without checking its hash. If a release uses a different payload, install it on A and require a new successful local acceptance-to-chat test **before installing it on B**. For this release we instead reuse the existing DLL with the proven hash. Package/version defaults now say test.2. CI still compiles/tests the tag, but its automatic release-upload job explicitly skips `v0.1.0-test.2`; its rebuilt artifact must not replace the separately uploaded A-tested Release payload.

### Remote acceptance release verification

The user authorized preparing/publishing test.2 for A/B modded and C vanilla, with no completion or further reverse-engineering work. Preparation rechecked the DLL in `poc/build` and the installed DLL on A: both still hash to `761A3124AC68F1DCC1AB8312BA5102E8046D5F9F708BF9A7F0708AEC158E4E87`. The game was closed at this check. No A reinstall or new local acceptance test is required if the uploaded/downloaded Release payload retains that exact hash. B must install the corrected Release ZIP; its old test.1 installation is insufficient.

The refreshed local ZIP passed curated nine-file/metadata/payload/checksum checks and all **18 extracted-package installer cases**. Acceptance filtering and proxy forwarding/wrong-build refusal tests also passed again. No native DLL was rebuilt or installed during preparation. The refreshed ZIP SHA256 is:

```text
82DCDC5BB8EC63B1354E12C17D742A7BC9755F24B9C8A50DE78BF8D1DED29425
```

**Published at 14:56:10 local (19:56:10 UTC)** as a diagnostic prerelease, release ID `454708819`. Download [DIDE-CoopQuestActivity-v0.1.0-test.2.zip](https://github.com/caffeineLover/Banoi-Together/releases/download/v0.1.0-test.2/DIDE-CoopQuestActivity-v0.1.0-test.2.zip), with its adjacent `.sha256` asset. The public ZIP was downloaded without authentication and verified again: ZIP hash equals `82DCDC5BB8EC63B1354E12C17D742A7BC9755F24B9C8A50DE78BF8D1DED29425`; the DLL inside equals the exact A-tested hash above; manifest version is `0.1.0-test.2` and its payload hash matches. The package contains the current three-client instructions. **A's existing matching DLL remains the validated release payload; no repeat solo quest test or A reinstall is required.**

Tag source commit: `bf7f35cce40a9ec7dfa058014d234df50c03e07b`. [Tagged CI run 45063351045](https://github.com/caffeineLover/Banoi-Together/actions/runs/45063351045) passed compilation, acceptance, proxy and installer/package checks; its `draft-release` job was explicitly skipped as intended. That rebuilt CI DLL was **not** used for the Release. The published ZIP and tag must remain immutable. The old test.1 release was unchanged. No multiplayer results have been supplied yet.

## Remote acceptance test record

Use the step-by-step [README remote test](./README.md#remote-acceptance-test). Test only one action at a time, allow the dialogue to finish, and record receipt immediately because the chat has limited visible history. Do not manually type the automatic message. Confirm the same release DLL on A and B before quest actions; C installs nothing. Initial planned host: A; record the actual host and all display names when the session begins.

| Preflight item | Current evidence |
| --- | --- |
| A installed DLL equals the required Release payload hash | PASS at preparation; exact hash above; prior The Lost solo gameplay pass |
| B installed DLL equals that same hash | Pending installation and confirmation on B |
| Fresh current-session READY diagnostic 3 on A and B | Pending launch/session; old solo READY is not fresh-session evidence |
| C completely vanilla | Required topology; confirm before the session |
| A manual test visible with correct sender on B and C | Pending explicit receiver observations |
| B manual test visible with correct sender on A and C | Pending explicit receiver observations |
| C manual test visible with correct sender on A and B | Pending explicit receiver observations |

| Automatic probe | Quest title / time | Sender's native log | Receiver observations | Result |
| --- | --- | --- | --- | --- |
| A accepts -> B and vanilla C | Not run | Not collected | B: pending; C: pending; require exactly one correct body/sender on each | NOT TESTED |
| B accepts -> A and vanilla C | Not run | Not collected | A: pending; C: pending; require exactly one correct body/sender on each | NOT TESTED |

Preserve complete current-run logs from A and B under unique local snapshot names, with host, accepting player, native ID/name, displayed title, approximate time, automatic-send/handoff counts, and each receiver's body/sender/count observation. C needs only observations; it has no observer log. Publish selected evidence and results here after each probe, without uploading full logs or private session data automatically. At a failure, identify **local acceptance detection -> quest ID -> displayed title -> stock send -> remote receipt**; do not infer a transport failure before checking the sender's earlier stages. Both direction rows must pass before moving to remaining acceptance cases, then completion.

## Test history and evidence

All events below occurred on **2026-11-22**. Times are local where available; log ticks are milliseconds, not wall-clock times.

### Startup and packaging

The original proxy and diagnostic 2 reached READY with supported fingerprints. A diagnostic-2 load produced 70 unscoped start and 21 finish callbacks, including manager mode 3, without automatic messages. This demonstrated why raw state callbacks cannot be treated as player actions. These observations did not prove load/rejoin suppression generally.

The initial hosted smoke test failed with module-load error 126 because the Windows runner lacked legacy system XInput 1.3. CI now installs the Microsoft-signed DirectX runtime on the disposable runner; no Microsoft runtime or game DLL is packaged. Another CI-shell issue left `LASTEXITCODE=-1` after intentional termination tests; the passing fixture script now explicitly exits 0. Installer review found interruption recovery and elevation-result issues; both received regression tests and fixes. The extracted-package suite subsequently passed all 18 cases.

### Failed coordinated Passport to Life probe

A/B/C reported sending manual test messages. A's log showed ordinary manual stock-chat handoffs with `automaticScope=0`; complete visibility of every manual message on every PC was not confirmed.

- Diagnostic 2: `B_Accept`, mode 0, tick `908213765`, thread `50540`. Dialogue choice changed `4294967295 -> 0`.
- **17.610 seconds later**, thread `33696`: owner `ACT1A_TalkToSinamoi01` / UID 32 finished, then `__ACT1A_Bloody_man_Pool` / 33, `ACT1A_WalkieTalkies` / 34 and `Steffen_Q1` / 372 started.
- The diagnostic deliberately skipped mode 0. It resolved no displayed title and made **no automatic sender call**. B reported no automatic message.
- **First failed link: local acceptance correlation.** This was not evidence of a networking failure. Picking the first child start would have identified the wrong quest.

Preserved local log: `.superpowers/live-test-2026-11-22/A-Passport-to-Life.log` (ignored, not uploaded). An additional earlier report about The Lost lacked a matching acceptance callback at that checkpoint and was ambiguous about manual chat versus accepting an NPC offer. Do not count that earlier report as a second proven quest or network failure.

### Successful diagnostic-3 local The Lost probe

A process 55344 launched at **12:56:37**. Startup tick `912132078`; READY tick `912132093`, expected fingerprints, all six hooks. The inspected initial load contained 47 quest-start callbacks and no automatic sends or initialization failures. Peter confirmed ordinary manual chat appeared locally after C -> `A local test` -> Enter.

Peter then accepted **The Lost** and reported: **“Phaedruss: Accepted The Lost.”** This is the user's visible observation; the exact outgoing body in the log is `accepted "THE LOST"`, using the offer's displayed capitalization. The mod did not insert Phaedruss or hardcode the title.

Selected log evidence, with transient pointers omitted:

```text
912446109 thread=68928 B_Accept pressed, mode=0 (press alone is not commit)
912446109 title resolution: displayed UTF-16 title=THE LOST
912446109 local actor equals participant; ownership=1; choiceBefore=4294967295
912446109 choiceAfter=0 pending=1; waiting for native phase commit; NO CHAT YET
912453750 thread=58556 talk ready match=1 phaseState=1 offerUid=372
912453750 group=Steffen_Q1_NF; captured resource equals use resource
912453750 result=Yes titleKey=&Steffen_Q1_Name&
912453750 phase finalize: state=1->2 nativeQuestUpdate=1 match=1
912453750 CONFIRMED mode-0 local offer and native commit: Steffen_Q1 uid=372
912453750 stock sub_0011E940, SayAll mode 0, message=accepted "THE LOST"
912453750 stock sender returned; stock remote handoffs=0
```

The UI input and committed phase ran on different threads, **7.641 seconds apart**. Exactly one automatic sender call occurred in the preserved current-run snapshot. This quest was already active: acceptance is the offer phase's committed `1 -> 2` transition, not a new quest `0 -> 1` start or a quest turn-in. Zero remote handoffs is expected with no peers connected. The user's visible chat observation establishes local delivery; remote delivery remains untested.

Full preserved local snapshot: `.superpowers/live-test-2026-11-22/A-diagnostic3-The-Lost.log` (ignored, not uploaded). The selected evidence above is the portable GitHub record. A full log may include personal/session data and should be reviewed before sharing.

### Offline verification of diagnostic 3

- MSVC x64 C++17 `/W4 /WX /O2 /MT` DLL compilation passed.
- Acceptance fixture tests passed after an initial stub failed 22 assertions. Coverage includes the recorded three-child ordering, same-owner acceptance, wrong actor/speaker/resource, no local input, uncommitted phase, wrong manager mode, wrong child/parent, rejection/reset, copied localized title, one consumption, and cross-thread handoff under the adapter's synchronization.
- Proxy smoke test passed all three XInput forwards, export names/ordinals 2/3/4, and wrong-native-build refusal without hooks.
- Test.2 package validation passed curated nine-file contents, payload/version checks, extracted-package integration and all 18 installer cases. These tests use fixtures, not the real installation.
- Protected archive hashes matched the original baseline. No original game file was modified.
- During this documentation/push step, a separate scratch DLL compiled successfully; acceptance tests, proxy smoke checks and all 17 standalone installer cases passed again. Documentation links resolved and the editor reported no errors. Installed and local diagnostic-3 DLL hashes still matched the successful live test; scratch compilation did not replace that payload.

Fixture tests prove filtering logic, not all engine relationships or multiplayer behavior. No live corrected child-quest path, joining-client action, vanilla receiver, full cancellation/control test, or load/rejoin matrix has passed yet.

## Verified native path and implementation

Native implementation: [poc/quest_chat.cpp](./poc/quest_chat.cpp). Mod-owned correlation state: [poc/acceptance.h](./poc/acceptance.h). Fixtures: [tests/Acceptance.Tests.cpp](./tests/Acceptance.Tests.cpp). Read-only PE/RTTI/disassembly tools are in [research](./research/).

All addresses below are **RVAs in `gamedll_x64_rwdi.dll`**, unless explicitly identified as engine addresses. `sub_` labels are analytical names, not invented/exported APIs. Full binary hashes and original slot values gate hook installation:

```text
gamedll_x64_rwdi.dll D10C7F59AD3BF62E7F2DD69CD7E49EB634D4E8D046E4F4C07463B5D589833545
engine_x64_rwdi.dll  7CF1F0153A2748DA55A36D89FCF2E451BA444468260355836722D3EF76B27C79
```

### Six observation hooks

| Native function | Original RVA | Slot storage RVA | Purpose |
| --- | --- | --- | --- |
| `MenuAcceptQuest` button handler, vtable +0x9A0 | `0x003FB7A0` | `0x00DCE248` | Observe exact B_Accept/B_Reject and copy displayed title; input alone never sends |
| `GameDI` quest-start callback, +0xBB8 | `0x001018C0` | `0x00D028A0` | Identify exact committed target; unrelated/load starts only log |
| `GameDI` quest-finish callback, +0xBC8 | `0x00101A20` | `0x00D028B0` | Log only; no completion announcements |
| `Quests::TalkPhase` readiness, +0x480 | `0x00806620` | `0x00F01B38` | Correlate same local offer/resource/speaker and briefing key; preserve original bool |
| `Quests::TalkPhase` finalizer, +0x478 | `0x00806EA0` | `0x00F01B30` | Observe original committed phase 1->2 in normal native quest update |
| Imported engine `IGame::MsgSend` | Engine export | `0x00C7E8B0` | Observe stock chat handoffs only; forward unchanged, no packet creation |

`MenuAcceptQuest` main vtable is `0x00DCD8A8`; GameDI `0x00D01CE8`; TalkPhase `0x00F016B8`; Quest `0x00EE5A08`. Each original executes once. Hook failure rolls earlier slots back. These are in-memory pointer substitutions, not inline instruction patches or on-disk game changes. The project's XInput proxy forwards the three imported functions to the existing system DLL. No third-party loader is required.

### Mode 0 confirmed local acceptance

1. Menu fields: Accept `screen+0x3B0`, Reject `+0x3B8`, title IUIText `+0x3D0`, actor `+0x488`, mode `+0x490`. Copy the explicit displayed wide title before calling the original. Exact engine export: `?GetTextExplicit@IUIText@@UEAAAEBV?$string_base@_W@ttl@@XZ`, engine RVA `0x0055B810`.
2. Use the menu's actual local-actor lookup: global `0x012822A8` -> game `+0x4A0` session -> session `+0xC0` holder -> smart pair `+0x60/+0x68`. This is verified at `0x003FA7E7-0x003FA848`. **The earlier local-context+0xA90 candidate was incorrect and must not authorize sending.**
3. Actor `+0xEC8/+0xED0` holds the dialogue-player pair. Its participant is `+0x78/+0x80`, speaker `+0x50/+0x58`, resource `+0x70`, choice `+0xC0`. Native mode-0 Accept calls `0x0066EE00(actor,0)`; after ownership guards it writes choice at `0x0066EEB1`. Reject passes 1. Require the exact local actor/participant, a valid resource, and choice `-1 -> 0` across the original button call. Automatic paths can also write 0 (`0x000C0243`, `0x000C026C`), so the field alone is insufficient.
4. Copy intent into mod-owned synchronized storage across UI/update threads. Match the later TalkPhase's **same resource and speaker**, finished `Yes`, normal manager mode 0, phase state 1, and valid briefing key. Reject special ready flags `0x21`; a true readiness return alone is insufficient.
5. TalkPhase finalizer `0x00806EA0` calls `0x007B68E0`; instruction `0x007B68ED` writes phase `+0xBC=2`. Snapshot before/after the original and require `1 -> 2`, with native quest-update stack return `0x007BA887` (nested check) or `0x007BA8AC` (root finalizer). Replicated/forced application outside that update does not satisfy this gate.
6. Resolve the offered identity from the first briefing speech key `&<internal-quest>_Name&` (or the verified bare form) and require an exact actual native quest match. Never derive IDs from English title text or pick the first subsequent quest start.
7. If the briefing names the already-active owner, capture its UID and wait for the exact committed offer phase. **The Lost live test proved this case.** If it names a child, also require that named child's state-1 start, exact owner parent and parent state 2. **Passport to Life's child variant is only offline-tested in the corrected build.**
8. Consume the pending observation once under an SRW lock, then call the stock chat sender outside the lock. New offers/rejection, changed local actor, or observed non-normal manager mode invalidate pending state. No persistent history or general per-event deduplication is implemented yet.

Quest layout: UID `+0x08`, narrow name `+0x10`, state `+0x3C`, root phase `+0x40`, parent `+0xB8`. Native getters `0x0085AFE0`, `0x0085B000`, `0x007BA3C0` verify the first three. Native start `0x007BA680` writes state 1 at `0x007BA6F4`, starts phases, then calls the GameDI callback at `0x007BA784`, return `0x007BA78A`.

### Dialogue and title identity details

TalkPhase owner `+0x70`, state `+0xBC`, group-name string `+0xF0`, cached group `+0x168`, speaker pair `+0x140/+0x148`, flags `+0x131`. Group resolver `0x00807960` populates the cache. The read-only map lookup equivalents are `0x000C6EB0/0x000C7A30`, guarded by group vtable `0x00CF6DB8`, state `0x00CF70C8`, dialog `0x00CF6748`. Group `+0x18` is the map root; node key `-0x10`, value `-8`, left `0`, right `+0x10`; state array `+0x10`, count `+0x18`. Traversal is bounded.

Kinds are verified by `0x000C73F0`: 8=`use`, 9=`use_second`, 10=`quest_brief`. Dialog finished byte is `+0x71`, result string `+0x78`. `0x000C6EF0` gets use; `0x000C6F40` checks finished/result; `0x000C7060` prefers use_second's result. The positive result comparison in `0x00806620` uses global `0x0128C618`, initialized to `Yes` by `0x00BEB020`. The action runner at `0x000BF7BE-0x000BF7FD` sets finished/result; the observer never invokes it.

The stock briefing reader `0x00735610` obtains quest_brief and localizes its first line (`0x007356BA-0x007357D6`); the menu stores that title at `0x003FAC05-0x003FAC73`. Dialog embedded block is `+0x28`, guarded by vtable `0x00CF6268`; block array/count `+0x28/+0x30`, i.e. dialog `+0x50/+0x58`. First speech action vtable `0x00CF57E8` (or interface `0x00CF5CA8` at main+0x68), speech-line interface `0x00CF5C18` at main+0x40, key string main+0x48. Constructors/getters `0x000C3650`, `0x000C53C0`, `0x0085B010`, `0x008A3990`, `0x000C4F50`, `0x0077C900`, `0x000C3C30`, `0x000CD390` establish these layouts. The adapter reads/copies them; it adds no engine getter calls to that traversal.

Original extracted files were inspected read-only: `DI/Data0/data/quests/act1a/act1a_main_quest.xml` around 3215 contains owner `ACT1A_TalkToSinamoi01`, talk phase Key Card - Start, Sinamoi group `Sinamoi_QF01_NF`; `dialogs/act1a_dlg.xml` maps its quest_brief first line to `ACT1A_WalkieTalkies_Name`. Main-quest XML around 3253 defines child 34. Side-quest XML around 830 and 13740 defines the other siblings. This explains why the three starts cannot be treated interchangeably. Do not distribute extracted assets. Internal/test developmental labels such as “Where is Maggie?” are not the displayed title; live The Lost was `THE LOST`.

### Retained mode 1 path

Mode 1 calls `0x00137A60` with `screen+0x498`, a selection string rather than a quest ID. The read-only lookup `0x00139BF0(this=0x01244BD8, selection)` resolves a row: signed 16-bit index at record `-0xBE` if byte `-0x54` is set, else `-0xC0`; bounds `-0x68`, row array `-0x70`, stride `0x38`. The exact row name is then passed by the original to `0x007CC890`, which may start the quest. The observer never calls the unblocking/start routine. It requires a thread-local original-button scope, the exact selected name, state 1 and native start return `0x007BA78A`; nested starts for other quests cannot count. This path is retained but is not what passed today's mode-0 live test.

### Ordinary chat and multiplayer

The stock edit-box submitter `0x0021E130` obtains game global `0x012822A8`, session game+0x4A0, and local-player context via session virtual `+0x7B8`, then calls **`0x0011E940(localContext, WideString*, 0)`** at `0x0021E1BC`. The mod obtains that same context and calls that same high-level sender. A wide ttl string is pointer + uint32 length + uint32 capacity (16 bytes on x64). Mode 0 is SayAll (`Hud_Chat_SayAll`, switch `0x0021EF1E`); modes 1/2/3 are Yell/Allies/Whisper. Do not pass GameDI as the local context or prepend the player name.

Verified stock path: `0x0011E940 -> 0x00132AB0 -> 0x00105450` remote producer -> engine `IGame::MsgSend`; local recipient path `0x001055F0 -> 0x0021E360` HUD. Remote producer constructs existing type-1 chat (byte 0 type, byte 1 mode, then UTF-16) and returns from MsgSend at `0x001054C6`. The observer only logs that caller and forwards unchanged. Exact export: `?MsgSend@IGame@@QEAAXIPEBEI@Z`, ABI `void(game, unsigned recipient, const byte* data, unsigned size)`.

Concrete receive dispatcher is GameDI virtual `+0x268 -> 0x00105330`. Type 1 advances packet data by one and dispatches through `+0xC48 -> 0x001054F0` at `0x0010539F`. The consumer uses network sender/`IGame::ReplGetTargetId` and `0x0012E940`, then ordinary local chat delivery `0x001055F0`. The engine base `onMsgReceived` slot is a default no-op at engine `0x00030420`: hooking that exported/default implementation would miss the concrete dispatcher.

**Inference pending multiplayer test:** ordinary native chat should deliver and attribute automatic messages just like manual chat on vanilla receivers. Static dispatch and A's local echo support the approach; neither proves remote receipt. No custom transport or quest-replication carrier is needed if this works.

### Completion blocker and replication cautions

Normal update `0x007BA860` checks a root phase, writes quest state 2 at `0x007BA8AF`, and calls `0x007BBF50`; the latter invokes GameDI finish callback at `0x007BBF66`, return `0x007BBF6C`. Other finish routes also write 2, including `0x007BA8D0`, `0x007BA950`, `0x007C50A0`, `0x007C7490`, `0x007CD9D0` and a path in `0x00816E79`. There is **no actor argument** on the finish callback. State 2 alone does not distinguish successful local turn-in from forced/automatic/replicated finish. Parent offer completion is not a completed-quest announcement.

RTTI verifies `Quests::Replication::QuestState` / `QuestStateContainer`, vtables `0x00F10A08` / `0x00F11258`. These show synchronized state, not an initiating-player acceptance/turn-in event. Actual export spelling is `IGame::GetIQuestManager`, not GetQuestManager; engine `0x0000A820` is a shared default. Concrete GameDI `+0x3D8 -> 0x00103270` returns singleton `0x01326E10`; mode is singleton+0x88 (`0x01326E98`). Do not invent meanings for all modes or use a default stub as the concrete manager. `0x00807B40`/`0x00115450` cache a speaker, but that does not establish the acting player for completion on host and client.

Missing completion links are **successful local turn-in attribution and its matching displayed title**, followed by stock send/remote verification. Do not announce all finished callbacks or infer causation from proximity/time. After acceptance is proven remotely, trace one natural turn-in and compare it with loading/another player's action before selecting a hook.

### Data3 and chat visibility

No verified exposed `.scr`/`.xui`/XML event/API provides this full local-causation/title/chat chain. Current implementation therefore uses a narrow native observer rather than a Data3-only mod. Arbitrary HUD text APIs and an acceptance network event with actor identity have not been established; do not claim they exist.

Peter observed roughly two readable chat lines and little accessible history. Read-only `data/menu/hud/hud.xui` has `HudMessages` / ClassOverride `HudMessagesDI`, `G_BottomQueue` around line 23716 and `G_TopQueue` around 23889; row templates `HudMessageElementDI`/`H_Html`, bottom HUDMedium/top HUDSmall. At 1280x720, queue heights 232/188 and about 34-pixel rows do not prove retained capacity. Native `0x0021D500` resolves edit/queue/template names; `0x0021D9F0` processes records including `0x0021F6C0`. `HUDChat` type name is `0x00D37668`, registration reference `0x00BF1ECA`. Default inputs.scr binds chat to Return, but Peter's actual binding is C. No dedicated history binding or hardcoded two-line limit was verified. No UI change has been made; defer capacity/expiry/history work until acceptance delivery works.

## Installer and distribution

Installer sources are in [package](./package/); tests in [tests](./tests/); packager [tools/Build-Package.ps1](./tools/Build-Package.ps1); CI [.github/workflows/test-release.yml](./.github/workflows/test-release.yml). Windows PowerShell 5.1 supports Steam registry/library VDF discovery, x64/native fingerprint checks, idempotent owned upgrades, conflict/running-game/reparse refusal, WhatIf, and UAC retry. It owns only `xinput1_3.dll` and `DIDE-CoopQuestActivity.install.json`, with a temporary `.install.pending.json` journal for interrupted-write recovery. Uninstall leaves unknown/modified files alone.

The ZIP contains the original compiled proxy, install/uninstall scripts and wrappers, helper, version metadata, README and MIT license. No development environment, external loader, game/system DLL or separate VC runtime is bundled/required on B. Existing system XInput is forwarded. CI installs legacy XInput only for runner smoke tests. Branch/PR/manual runs upload a package artifact; normally tagged `v*-test*` builds prepare a **draft prerelease**, with publication a separate step. Test.2 is explicitly excluded from automatic release upload to preserve the exact A-tested DLL. The first test.1 prerelease was published at the user's explicit request before gameplay validation; do not silently broaden that into a finished-v0.1 success claim.

Protected archive baseline SHA256:

```text
Data0 EDEC00F9ACA5C5C1A1B6C6BDB43C88D76D04FD689A3ED26DFBFFF9A3E6D46FE6
Data1 DD135F2DD76D62F37D4F93E22C34C951435422FF8C0DA162B505DA11DCC04A59
Data2 81313377FF1759FAC6D53A2CE69F0505AB355E89FDA1136046B85CF342EFD759
```

## Next steps and release gates

1. **Documentation checkpoint:** today's A pass is preserved above, and this checkpoint includes the corresponding diagnostic-3 source. Overlapping trace/testing/plan documents have been consolidated and removed. No more quest acceptance is needed for the current local result; A can exit normally.
2. **Release checkpoint complete:** test.2 is published using the exact A-tested DLL, with refreshed docs/version and passing package tests. The public download's ZIP/DLL hashes and version were verified independently. No original game file, installed DLL or test.1 asset was changed. Use this immutable Release asset; any different future DLL requires a new local A gameplay pass before B installation.
3. **Current next gameplay milestone: remote acceptance in both directions.** Install the exact Release package on B; C installs nothing. Confirm A/B identical hashes and fresh READY diagnostic 3. Verify all six manual-chat recipient observations. A accepts one natural quest; require one correctly titled, ordinarily attributed automatic message on B and C. Record it, then repeat with B acting and A/C receiving. Update the record above and preserve logs. Only when both directions pass, continue with remaining host/joiner and negative-control cases. A stock remote handoff with no visible receipt narrows failure to remote delivery; no handoff narrows it to sender/recipient emission. Do not infer either from a missing line alone.
4. **Check acceptance negatives and unsupported variant.** C accepts while A/B only observe: no automatic observer messages. Opening/rejecting an offer, loading/rejoining, replication and unrelated starts must not announce. Test the exact named-child variant through normal play when available; no state reset.
5. **Then trace one successful local turn-in.** Keep completion logging-only until actor, successful outcome and title are proven. If it remains harder, ship/report the working acceptance event separately and identify the missing completion boundary.
6. **Add minimal in-process duplicate suppression** based on proven event kind/quest identity and load/rejoin handling. Current consume-once pending acceptance is a useful first guard, not a fully validated event-history policy.
7. **Usable v0.1 release gate:** pass the matrix below before claiming required acceptance+completion functionality works.

| Required multiplayer case | Result |
| --- | --- |
| A accepts -> B and vanilla C receive one correct message attributed to A | Not tested with diagnostic 3 |
| B accepts -> A and vanilla C receive one correct message attributed to B | Not tested with diagnostic 3 |
| A successfully turns in -> B/C receive correct completed message | Blocked: completion observer not established |
| B successfully turns in -> A/C receive correct completed message | Blocked: completion observer not established |
| C acts -> A/B send no automatic observer messages | Not tested with diagnostic 3 |
| Load/rejoin -> no replayed/obvious duplicate activity messages | Initial solo loading showed no sends; full case not tested |

For any failure, record the first broken boundary: **acceptance/completion detection -> quest ID -> displayed title -> stock chat send -> remote receipt**. Current feasibility: **local acceptance demonstrated for one path; multiplayer and usable acceptance+completion version remain unproven**.

## Local development notes

- Workspace: `C:\Users\Peter\Desktop\home\code\DeadIslandGhaelenMod`, PowerShell. Local branch `prepare-test-release`; remote main also has user README edits that must be preserved.
- Git ownership requires per-command `git -c safe.directory=C:/Users/Peter/Desktop/home/code/DeadIslandGhaelenMod ...`. Do not add a global safe-directory exception. Never force-push main.
- Read a live gameplay log with `Get-Content`; `.NET ReadAllLines` can hit a sharing violation. Select the latest `Quest Chat diagnostic ... startup:` segment before counting sends, because the log appends across launches.
- An older Steam run inherited a sandbox TEMP directory; check the current process/run rather than reading a stale log. `.superpowers/` evidence and build/dist outputs are ignored. The isolated `research/smoke-build` log is never gameplay evidence.
- Use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...` for repository scripts where the shell execution policy blocks them. Package tests are fixtures and do not install into the real game.
- `Disasm.ps1` defaults can stop at a small `.pdata` fragment; use an explicit end RVA when tracing a complete logical function. Local dumpbin is under `C:\BuildTools2026\VC\Tools\MSVC\14.52.37025\bin\Hostx64\x64`.
- GitHub connector reads worked but writes returned 403; authenticated git push worked. Existing credential-manager credentials can be used without printing or writing tokens. Do not place secrets in logs, docs or Git.

## Documentation consolidation

This record replaces the overlapping `TESTING.txt`, `ACTIVITY_TESTING.txt`, `NATIVE_TRACE.txt`, `ACTIVITY_TRACE.txt`, `MODE0_TRACE.txt`, `CHAT_UI_TRACE.txt` and the completed test-release plan. Their useful evidence and decisions are incorporated above; tracked historical versions remain in Git. Temporary untracked research notes were consolidated before removal. Release notes are a short workflow-generated pointer to the README and this record, rather than another maintained status file.
