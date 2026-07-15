# Psych 1.0.4 — Clean Fixes Changelog

This branch (**`psych-1.0.4-fixes`**) is [Psych Engine **1.0.4**](https://github.com/ShadowMario/FNF-PsychEngine/commit/5c67ced49e5a98535298a6daa3f8f4ec79ac8399)
with **only** haxelib/toolchain updates, bug fixes, and performance work backported from PE Continued.

The goal is a clean, modern-toolchain base that people still on stock Psych 1.0.4 can
build against and cherry-pick from.

Baseline: [`5c67ced`](https://github.com/ShadowMario/FNF-PsychEngine/commit/5c67ced49e5a98535298a6daa3f8f4ec79ac8399)
("Update gitVersion.txt", 2025-03-24) — stock Psych Engine 1.0.4.

Every commit below is linked to this repository. Grouped by type, newest-toolchain first.

> **Intentionally kept from stock 1.0.4:** `hscript-iris` (Iris was **not** swapped for
> Insanity) and Dot-Stuff `flxanimate` (**not** swapped for MaybeMaru's `flixel-animate`,
> which regressed atlas offsets). `hxluajit` **does** replace `linc_luajit`.

---

## Libraries / toolchain

| Library              | Stock 1.0.4        | This branch      | Notes                                                              |
| -------------------- | ------------------ | ---------------- | ------------------------------------------------------------------ |
| `flixel`             | 5.6.1              | **6.1.2**        | **Major** upgrade                                                  |
| `flixel-addons`      | 3.2.2              | **4.0.1**        | **Major** upgrade                                                  |
| `lime`               | (transitive)       | **8.3.2**        |                                                                    |
| `openfl`             | (transitive)       | **9.5.2**        | Needed a `PsychUIInputText` caret clamp (RangeError)              |
| `hscript`            | (transitive)       | **2.7.0**        | Now explicitly pinned                                             |
| `hscript-iris`       | 1.1.3              | 1.1.3            | **Kept** (not replaced with Insanity)                            |
| `hxvlc`              | 2.0.1              | **2.3.0**        | + `precacheVideo` warming API                                     |
| `hxdiscord_rpc`      | 1.2.4              | **1.3.0**        |                                                                    |
| `hxcpp`              | release (system)   | **git `v4.3.143`** | Pinned tag; built from source in setup                          |
| `hxcpp-debug-server` | (not listed)       | **1.2.4**        | New pin                                                            |
| `tink_core`          | (transitive)       | **2.1.1**        | New pin                                                            |
| `flxanimate`         | git (Dot-Stuff)    | git (Dot-Stuff)  | **Kept**                            |
| `linc_luajit`        | git                | **removed**      | Replaced by `hxluajit` + `hxluajit-wrapper`                       |
| `hxhardware`         | —                  | **git (new)**    | CPU/GPU/memory metrics for the FPS counter (`HARDWARE_ALLOWED`)   |

---

## Build, setup & CI

- [`a241978`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a241978aa1d5571f706ca2a0fcb1d936c1a90c3b) — Fixes for newer haxelibs
- [`48a58cf`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/48a58cf4fbb96ccf7707d311d294326706672dc8) — Create hmm.json
- [`7a3e240`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7a3e2403f585c4c6a675ed0a68509ceb0231a01c) — Update hxformat.json
- [`7d1a63c`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7d1a63ccf9289cc84757dd64f6833adfc2d1c5c3) — Source code formatting is now consistent across all classes
- [`59f84cf`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/59f84cff5687c60f334f425c575d41c0303b339a) — Migrate from linc_luajit to hxluajit + hxluajit-wrapper
- [`93af562`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/93af562c4674542ba05901139eab8a55a8c82b18) — update haxelibs and build scripts
- [`177277c`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/177277cb3d6df951e77b15bd76ba98d771bd9605) — fix build: use local haxelib repo, correct funkin.vis url, pin tink_core 1.26.0
- [`75a43a1`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/75a43a1c64ea3cefcbb315c5c51c9afdd13d787e) — build: patch funkin.vis for current grig.audio API, build hxcpp tool in setup
- [`4d9da58`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4d9da589a713c8835413ecce035692de33c4f349) — Setup/CI: pin hxcpp v4.3.143, bump hxvlc 2.3.0, installGit ref arg, local repo; modernize build workflow
- [`90dca25`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/90dca2591ddf67fbe568bd0583c8f9a02a353417) — Make the VIDEOS_ALLOWED define not messy (desktop || mobile)

---

## Multithreaded loading fix

Fixes song-load softlocks in the multithreaded loader (single-task prep, stall watchdog, thread cap).

- [`5608cff`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/5608cffc25b408c3bbdb0eb677a766fa1f562cf2) — LoadingState: Fix multithreaded song-load softlocks
- [`91e41aa`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/91e41aa5eb48ace2e038673040e150e7b561aecb) — LoadingState: Single-task prep, remove Future/latch
- [`87a1a5e`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/87a1a5ebd465be3341f007a4f9786f586bb9f8c3) — LoadingState: Add load watchdog + thread cap

---

## Ported additions (non-feature: perf/tooling only)

Small, self-contained additions that don't introduce new gameplay systems — a
CPU/GPU/memory **FPS counter** overlay with its pre-SmidrUI options submenu
(`hxhardware`/`DebugPrefs`), **video precaching** (hxvlc 2.3.0 `precache()` +
`VideoSprite` reuse), and **clang-cl** Windows build support:

- [`9b269f5`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9b269f5e838e81a7a69fe6a644f072c232e37987) — FPS Counter: CPU/GPU/memory performance overlay + FPS Counter Settings submenu (hxhardware, DebugPrefs, pre-SmidrUI options)
- [`dd035d6`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/dd035d6991e9e548d7488784d8c9e16f08552bed) — Video: hxvlc 2.3.0 precache + VideoSprite reuse (precacheVideo warming/adoption)
- [`3d05358`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3d053580edd7cdffadcb6564368fbbe9eb007637) — Support building with clang on Windows

---

## Performance / optimizations

- [`7aa2dc6`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7aa2dc6d3e151cdc4f0e013e3b66b8f1aa251bcb) — Perf: skip redundant indexOf scans in note-spawn loop
- [`daed24b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/daed24b1f3d2c9a48053f1ac59211658c8ff30e5) — Perf: only push curDecStep / curDecBeat when they actually change
- [`f6c7e15`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/f6c7e15de133daaf1b9c04ceaae5c54612fd737d) — Perf: short-circuit BPM-map walks once past the target time/step
- [`5163e8c`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/5163e8caccb0cec784c1f049848ebb643745cdcf) — Perf: cache FlxKey -> strum-index map for keyboard input
- [`c920bb7`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/c920bb7bc2c99e8493e0590469b9d183fd293bf9) — Perf: reuse keysCheck buffers and avoid Array.contains scans
- [`4c47621`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4c47621f896c8114e7e01440930a4d0e33d7581f) — Perf: avoid per-call allocations in script-callback dispatchers
- [`9ffd5ee`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9ffd5eea48df3e85bc9b6e400693e9d5f778829f) — Perf: pool the args buffer for Lua -> Haxe callback dispatch
- [`854ac33`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/854ac337ebf4589ba12d51f18866a6303feb2386) — Perf: inline stagesFunc at hot-path callsites
- [`be7d564`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/be7d564408f15e8e54df02e9b1de2aae81527b10) — Perf: pool FlxSprite instances in popUpScore
- [`2b69f30`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/2b69f30c962a3764a74b1d0a5e6909f921bcdc4a) — Perf: dedupe per-song hitsound precaches in Note.set_noteType
- [`4a02fdd`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4a02fdd756ef9a8c786dc2eb3a817e8dbb48e095) — Perf: drop redundant Paths.mods() call in directoriesWithFile
- [`7b1d6d4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7b1d6d41ea06f4c60db69215732e3023bf4a75bc) — Perf: inline stagesFunc in MusicBeatState.update
- [`9993139`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/999313902a79c32e5af02dc083bc4a8ed7aa65f6) — Perf: stop flushing the save on Highscore.get* lookups
- [`70bc634`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/70bc634279ff69a77999695cc42e8dc4e896f332) — Perf: cache Mods.parseList result per-state
- [`ba08683`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/ba0868397d6b0b312073d8421031f1325b63dbe0) — Perf: FPSCounter ring buffer + skip redundant TextField writes
- [`3a1db37`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3a1db37d4b3266e7aed30049a62ebd9059b68aa4) — Perf: skip tag.split allocation when tag has no dot
- [`c98fd20`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/c98fd20b8f564db2835b48cb151e7801d15bb92f) — Perf: cache pixelUI Paths.image lookup in StrumNote.reloadNote
- [`729a660`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/729a6603bb04b5310b1b98078d99c4e7fe09c8fa) — Perf: Controls input checks cache binds and dodge iterator allocations
- [`170b074`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/170b0749875d01b08f5b23c17babbc18c4c46e37) — Perf: MusicBeatState only writes save.fullscreen on change, inline stepHit loop
- [`f0f5c14`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/f0f5c14b454226d4e88832cf36a45adfc96e2691) — Perf: Language.formatKey hoists regex to static

---

## Bug fixes & cleanups

- [`6847dd3`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6847dd386fd61ad28727ca6597dbf2c0519af9a4) — Fix Note.get_hitsoundVolume infinite recursion
- [`0b327f0`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/0b327f0305e1a2cbbdd0882238701129d56d54cb) — Fix infinite freeze when a notes-group member is null
- [`dc86ad4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/dc86ad42ea8ff87c00c3439e8d93a411d036b60c) — Fix Conductor.getStepRounded operator-precedence bug
- [`9c5b232`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9c5b232a4a433fba8139936500737a9aa8c14c5f) — Fix CallbackHandler dispatcher not updating lastCalledScript
- [`6113855`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6113855ac9c2561237faf7cad88a07be8eb2c212) — Fix StrumNote off-by-one bounds check on arrowRGB lookup
- [`ba35915`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/ba359153b12706ec10ada1033b768d8b54993e3c) — Fix Note.defaultRGB off-by-one bounds check
- [`9c4debe`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9c4debe7c5005faf68c4a8fd4f7fdb62bbeadf33) — Fix popUpScore skipping sprites by mutating comboGroup mid-iteration
- [`3cc205d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3cc205d7acbc96e9bd5ef119d9631be6c9e5141b) — Remove stray debug trace from Conductor.mapBPMChanges
- [`adfe96a`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/adfe96a03d054484ab7ea0117a140b09773c1d3c) — Drop redundant second assignment in Conductor.set_bpm
- [`0b4886b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/0b4886b6d88d1919e7393bc3849d72b6e1de796f) — Fix: Paths.getTextFromFile passed Bool as parentfolder
- [`f65c2fd`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/f65c2fdaa11ec6878970e0259b186d86d7826a79) — Fix: anyGamepadPressed Lua/HScript callbacks missing return
- [`6548b9d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6548b9da0d8a2bb4c46ca796a02f8eac7fbcc239) — Fix: getRandomInt/Float skip empty/invalid exclude tokens
- [`75f59cf`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/75f59cf7ef3b109e3e94e8f41b6b7a419f8a869d) — Fix: Paths.image cache key now folder-aware
- [`f9f883b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/f9f883b8c7b347088980e0dcda6e7e847e7aac2f) — Fix: HealthIcon guard against zero iSize on tall/square graphics
- [`98da449`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/98da449875cca589d5b6e3612ce9d6fa4e6b13b4) — Style: fix startDialogue else-branch indentation
- [`d0ccce4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d0ccce4244be747693453eb1b6a60afcecbfa6e6) — Fix: NoteTypesConfig.loadFromTxt no longer falls through on null/invalid file
- [`a4d4b6e`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a4d4b6e5b252beddda2eed215aa6ae799414fa8b) — Perf+Fix: CoolUtil hoist regex, single-lookup color map, fix substr no-op in browseFolder
- [`5c8d161`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/5c8d1613362ed4a52d7a481d00f43aee62391dbd) — Fix: Achievements.getScore no longer crashes on non-score achievements; fix errorTitle precedence
- [`3950a55`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3950a556ca52d2496a55f9a7978d302e62aaa98b) — Fix: Difficulty.loadFromWeek walks index 0 and uses splice instead of remove-by-value
- [`49b2acf`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/49b2acf9aed1a03f0fc820d15d2b62f343b5485f) — Fix: StageData.getStageFile catches parse exceptions and falls back to dummy
- [`a399a05`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a399a05a45b1d4055d8e7c9a952d2d42b31ef000) — Style: Conductor.judgeNote drop redundant data alias, cache last index
- [`13c1595`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/13c15954bc119a92a1d628cc0b9c0b3876cde830) — Fix: short-circuit getSparrowAtlas/getPackerAtlas/getAsepriteAtlas on null image; guard pixel Note/StrumNote loadGraphic against missing skin (was producing 'null' asset id spam); drop leftover psychic debug trace
- [`d8a9f06`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d8a9f064d8b724458ff6379c06e21279878a6bf9) — Fix: regression in arrowRGB bounds check broke right arrow
- [`1c1bc94`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/1c1bc948eeb6df0a0d5e06b18bed007abbaa0adc) — Fix: popUpScore pool reset velocity/acceleration on acquire
- [`b1e467a`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/b1e467ae47b68980c7274c2589719a2e14820213) — FlxText: respect antialiasing pref by setting FlxSprite.defaultAntialiasing
- [`e841832`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/e841832cfc4f63fa72c16f4baa71a4b7d368d1ed) — OverlayShader: fix invalid GLSL syntax in blendLighten
- [`a187709`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a18770926d7822c8e202bc4acd0b4792c8f585fc) — DialogueBoxPsych: fix infinite loop on null dialogue entry
- [`07d2a8b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/07d2a8bdd9a065c177377ef452b56d90b830e8b5) — Character: fix inverted animPaused for atlas characters
- [`4ae45c0`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4ae45c050ae9e60a74a36c4f5883777a8273b854) — MenuCharacter: fix missing-character fallback and add null guards
- [`1e13f05`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/1e13f0573691f31bbf5128f4148c3140400c5df0) — Options: null-guard 'options' array in STRING-type option constructors
- [`9a60223`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9a60223fe1b0caddb337570df6c3f647ed298719) — StageData: fix validateVisibility dangling-else and unreachable branch
- [`50abdb8`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/50abdb8e2bb29cc25122b38ec72c2f816a14ad8a) — Conductor: guard judgeNote against empty/null rating arrays
- [`2714398`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/271439848951fa785e136ce0c3728a38aa649c9d) — PsychUIInputText: fix Ctrl+C/Ctrl+X failing when selection starts at index 0
- [`3e19753`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3e197539cbc1ee62e8ab1cfefd086f710b464288) — PlayState: fix ghost-note skip due to concurrent unspawnNotes mutation
- [`a0783f3`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a0783f358f84176d9670de55f1e583432106d3cd) — FreeplayState: fix per-song saved difficulty never being restored
- [`cc61558`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/cc61558678571e771a796ff54c11ec6d61f9dbb0) — LoadingState: remove stray space in music extension passed to clearInvalidFrom
- [`412a09d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/412a09d46ef6ff842a37ca7f036cf35a48595f15) — Note: fix initializeGlobalRGBShader bounds check for RGB triple
- [`6fdc902`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6fdc9029289059074131d05a25a7d47902df20da) — MusicPlayer: fix updatePlaybackTxt NPE on whole-number playback rates
- [`ee60dcd`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/ee60dcde9aa3d3c0a8f21682fb2a0c2669d7497a) — FunkinLua: getBool now accepts real Bool values from Lua
- [`0409388`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/040938855a8a10903d83ac87309e253b086d66a6) — FunkinLua: read Lua error message from top of stack, not status code
- [`db8fb04`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/db8fb042c2612284e13b2018a3597ca34d21276e) — FunkinLua: store/remove startTween under canonical 'tween_<formatted>' key
- [`393e135`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/393e135e08d2048a12f0a28a26c21223d0472faf) — FunkinLua: setSoundPitch now targets music when tag is empty + drops dead double-apply
- [`23a60ca`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/23a60ca9bb3ae5facb897b937df66bb6c59905d7) — LuaUtils: guard isMap against null input
- [`a94c356`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a94c3563e8d2cf9923cca5e2f6208c8d369480ab) — CallbackHandler: guard PlayState.instance / luaArray before scanning
- [`dc1da51`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/dc1da51c56332c03cb68cb7dc41791b2edf5f68b) — ReflectionFunctions: stop walking method path once an intermediate is null
- [`da9171d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/da9171ddeb32001b618ded90e45401fdd398436b) — ModSettingsSubState: fix Map<->Array fallback and call super() before close()
- [`d37180b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d37180b629abac43c4a1fe82a3fd73e2abb7d0a8) — NotesColorSubState: fix swapped pixel/non-pixel branches for skinNote
- [`02bd945`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/02bd9459247cca4d4ec9b57472e276ec633befe1) — DialogueBox: deactivate empty dialogue substate and null-check finishThing
- [`e461c9f`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/e461c9faf75e2e704027113cc9d56763cd2cd6db) — PsychFlxAnimate: trim myJson (not pathOrStr) when deciding path vs raw JSON
- [`2c33ea8`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/2c33ea858460ea64b97652d783e0d53808f46e70) — Achievements.reloadList: stop mutating StringMap mid-iteration
- [`3374950`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/33749508edf912e00e44e8ceac57cdecf3767eb9) — PsychUINumericStepper._updateValue: actually strip stray minus signs
- [`93031c6`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/93031c6530b8932cd03e1dcd7a5b7abdea775aa1) — NoteTypesConfig._propCheckArray: treat first segment as a property
- [`3ae82e3`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3ae82e3700f68fbb261aaae2321f7f20649c204e) — StageData.addObjectsToState: dedupe characters by role, not by name
- [`940a66d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/940a66d8d3ff8ae7d0970cd4c7cc200eaa0df4b4) — Note.set_clipRect: bypass setter recursion and bounds-check frameIndex
- [`744ff7b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/744ff7b6382f28ffbf7056913c96116d21fcd92e) — TypedAlphabet.update: subtract delay instead of clamping to 0
- [`e6d79c8`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/e6d79c8c8c85f88da7601ef2946b8c1b7579bf19) — AchievementPopup: actually store and invoke the onFinish callback
- [`19031e7`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/19031e7c0f58387973e7627369b62ee895dfc4ed) — Character.draw: always restore alpha/color before returning
- [`eec77d1`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/eec77d1fdf07014bc68db5a4d420f1e4ae246789) — Character.destroy: free missingText and run unconditionally
- [`a32d20b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a32d20bd9a400adb63a0a57307c71a2b6d4e82c0) — NoteSplash.loadSplash: null-check config.animations before Reflect.fields
- [`6281175`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6281175820765f5dad6f7a4f5dbe191051eb4f0b) — NoteSplash.loadSplash: seed default offsets when txt config is blank
- [`1be0c20`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/1be0c201395c2496a678467bfd513531868b741d) — FunkinLua.setSoundVolume: route empty tag to FlxG.sound.music first
- [`60cd971`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/60cd97175a0b1494495a743a8a2350797b9173db) — ReflectionFunctions.getPropertyFromGroup: use realObject for switch
- [`4a01ebc`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4a01ebc49c2ab35946342f302b6a604714c5014b) — CustomSubstate.openCustomSubstate: null-guard PlayState.instance.vocals
- [`5cc7d11`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/5cc7d1172092fb1061bc6594d7b314313507a806) — HScript ctor: also catch generic exceptions from execute()
- [`a0365aa`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a0365aab7c0703d51cf485fbc0a7e65299756421) — HScript.call: skip Reflect.callMethod on non-function variables
- [`6f75c6a`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6f75c6a66a1adb5f9094a86b623443d4985b13ae) — HScript addHaxeLibrary: re-check funk.hscript after initHaxeModule
- [`59cdc48`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/59cdc48cf143363bf59dda012d8cd8f40da5fe23) — LuaUtils.setVarInArray: parse numeric bracket index as Int
- [`83cae66`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/83cae669443ae101ea0bc547aca4247d2510c321) — LuaUtils.getVarInArray: parse numeric bracket index as Int
- [`d16492e`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d16492e2984b12448ebea4841af218d6b4ac1472) — LuaUtils.getModSetting: validate settings.json root is a JSON array
- [`c227c55`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/c227c5540ae995f796f38be749876f3fcebbd438) — BaseOptionsMenu.closeBinding: remove from group before destroying
- [`21b8258`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/21b825848ed53d93d316df11f56c250b4eed0cbd) — OptionsState BACK handler: null-check FlxG.sound.music before write
- [`b8488de`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/b8488dec2d2a7f0952892b482f2efda9649af19c) — NoteOffsetState: null-check FlxG.sound.music before volume/time reads
- [`d591b15`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d591b15c96c86323d2c4bfac1d038a99487ea829) — CutsceneHandler.update: null-guard finishCallback
- [`20a5161`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/20a5161b604d4a4b033cfc62f37ebbdc691ef503) — CutsceneHandler: remove from state before destroying
- [`ba9463e`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/ba9463e55bcea8aa183494eb8318d649c8a34186) — DialogueBox.cleanDialog: bail when speaker name has no portrait suffix
- [`ab2e2ac`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/ab2e2ac1397eba329e122e935514d15475425b6d) — DialogueCharacter.playAnim: null-guard leAnim before animation.play
- [`dca49d4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/dca49d4794210d1e68b773533a6492cf904b8e79) — DialogueBoxPsych.spawnCharacters: skip null portraits
- [`27b58dd`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/27b58ddc45070e0982b0331e99edaaefa2af2d3e) — DialogueBoxPsych: null-guard box.animation.curAnim at dialogue end
- [`23c7912`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/23c79122bcfa2841d6181453956a6d949014149a) — RGBPalette.cloneOriginal: only lock allowNew after a successful clone
- [`deb6173`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/deb6173ac744d701e5557075e5a1face3c0c3eb3) — PsychFlxAnimate.destroy: null-guard anim and anim.metadata in catch
- [`9a58cc1`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9a58cc16a1375f31fa6cbfea6faa53d4d3119354) — MusicBeat(Sub)State.rollbackSection: fire sectionHit on rewinds too
- [`30b14aa`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/30b14aa7f8d2c868573712a8e320c23677d4285f) — BaseStage ctor: call super() before any instance work
- [`93aed19`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/93aed19c6194cf483f49847841be3ca2295c17e4) — FlxAnimateFunctions.addAnimationBySymbolIndices: drop null parseInt results
- [`4c85b85`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4c85b85bcd1edd31ae44ad3710f2fe962e52c86c) — DeprecatedFunctions.luaSpriteAddAnimationByIndices: drop null parseInt results
- [`d26e166`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d26e16694dfc2238051d56d5be37852bceb09040) — LuaUtils.addAnimByIndices: drop null parseInt results
- [`1f505fd`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/1f505fdb4af9d4e524fc76585f4cef3d406cb32b) — Song.convert: guard null note type before defaultNoteTypes lookup
- [`cab1ec8`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/cab1ec82145b16c59b7d6fa64fdd5216f61e9aaa) — MainMenuState: detect mouse motion on either axis
- [`7c8a648`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7c8a648ea7b23913bc8e9a5291d50767e4d2dbff) — LoadingState.prepareToSong: null-guard stageData.hide_girlfriend
- [`f5a81b3`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/f5a81b358ef1768fd4c4e77b20f1a8644ceb8e38) — ClientPrefs.reloadVolumeKeys: null-guard volume bind lookups
- [`94ae58a`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/94ae58a0433d2e6cc6eb74a82df69dce447233f8) — WeekEditorState: drop non-numeric components when pasting bg color
- [`2391383`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/2391383d09c459bee308cf1c1b3042c1a5f92bbd) — CharacterEditorState: validate animation indices via null check
- [`fd8ea47`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/fd8ea47106ceec99145e802999be21bba8e0994f) — StageEditorState: validate animation indices via null check
- [`b30223e`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/b30223e29ea39b2637264401efce4d122ca9bbde) — AchievementPopup.drawTextAt: pass width/height to drawRect, not x2/y2
- [`3ac2239`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3ac2239cc12ec4cc973bb1c6adff0ea4ee9064b5) — Paths.clearUnusedMemory: stop mutating StringMap mid-iteration
- [`f4b0c4e`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/f4b0c4e27430d81b412327a9268632d6da8e7751) — Paths.clearStoredMemory: stop mutating StringMap mid-iteration
- [`7680c55`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7680c555345731de8549c2300c8e760eae4871ca) — Paths.freeGraphicsFromMemory: stop mutating StringMap mid-iteration
- [`3b3752d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/3b3752d5da0a395b9431ad6ee7d62e3379fce7a0) — fix(CreditsState): require non-null URL before browserLoad on ACCEPT
- [`0357157`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/0357157fbb71166b8708d863c8753d43030506d2) — fix(ModsMenuState): null-guard initial settings-button enable check
- [`8d660ac`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/8d660ac66ae6ccad03c2d67b08dfc59e936b0318) — fix(PlayState): default Change Character charType via null check
- [`7bad4b8`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/7bad4b83fd275fd4ca2b767e3b3565b409a0bb7f) — fix(PlayState): default Alt Idle Animation char index via null check
- [`08219d6`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/08219d61d4610d811212025ed92b6f52b5f89066) — fix(PlayState): default event-loop Change Character charType via null check
- [`4cd1250`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4cd1250015155d3e4519ab3ad11b2889ce67bbcc) — fix(NoteTypesConfig): bail _propCheckArray on malformed bracket index
- [`4ff5923`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4ff5923f2dc1f7d90e2fb3a389ccb14a4cfbda89) — fix(ErrorHandledShader): stringify Dynamic error before saving crash log
- [`b352d2f`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/b352d2fee2c96b0f643725d618fd31f97027cdf6) — fix(FunkinLua): guard noteTweenFunction against modulo-by-zero strums
- [`16ab2bb`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/16ab2bb1bb1d1e07e82b35de43fba90cb28cac87) — fix(LuaUtils): use safe-cast syntax for Int->Dynamic key coercion
- [`55e7763`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/55e7763f15ee933f1f077c301aeba31d8ffdf770) — fix(LoadingState): silently skip preloadCharacter when JSON missing
- [`24928d2`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/24928d2fc932b950a7b45fd45c425e6f530a1a83) — fix: clamp caretIndex in PsychUIInputText.updateCaret to avoid openfl 9.5.2 RangeError
- [`86c3f12`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/86c3f1298f20731f05dd4aea78e3a7e5e3af0ee7) — fix(chart editor): disable antialiasing on grid sprite so cells render crisp
- [`9dd00fa`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9dd00fa67a66394d6a2711f0635a07b0dfcb68aa) — PsychUIInputText: fix caret drift on backspace and typing
- [`74ff57f`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/74ff57fb8c276a074bdfe05f0996ad71a58b1b35) — ChartingState: Fix selection box not working after Flixel 6 upgrade.
- [`69b2f92`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/69b2f924a452910151cca4917054084f5932eb4d) — Fix .scroll variable not working on float option entries
- [`1c631dd`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/1c631ddb22d99df94ef74009d9e9e90bc264e1f7) — GameOverSubstate: defer neneKnife destroy to avoid null-ref on finish
- [`d42040c`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/d42040c4c8ec4d72e436c0f7bcfc8cd95979aaea) — Null error related to center strum notes
- [`b865779`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/b865779dc39c57d0e274554444639b8b362f77a9) — Paths: sanitize path separators in formatToSongPath
- [`0f41d6d`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/0f41d6d59e15275edb664d285aec3b78eb9b1714) — ChartingState: Skip corrupt [time, 0] events instead of crashing on load
- [`9cefe12`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/9cefe123cfcdd193a645b7d6680e33f9dbd162e0) — CustomFadeTransition: time-based FPS-independent sweep + faster
- [`23ddab4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/23ddab45f91868b33435a97ccd191791a1b48e54) — Main: Keep fixedTimestep disabled across game resets
- [`a13e0c6`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/a13e0c6ee52d113dd62bfe5c0a9b9efd4af53705) — Bump version, Project.xml cleanup and remove the officialBuild gate.

---

## Asset repacks

Repacked base-game/shared spritesheets (smaller atlases; frame names preserved). The
`menu_achievements` sheet is restored to the original because the repacked one was buggy.

- [`79e4eff`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/79e4eff4d1069829693d50477648a63f225f7498) — Assets: Repack shared spritesheets
- [`1ae7667`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/1ae76674f6a9d7b46f88a8dc877a1cb4d46a9e31) — Assets: Repack base_game spritesheets
- [`b1a6000`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/b1a60009e9b175919788b3d90d2ed465dfb083c1) — Restore old menu_achievements sheet (new one bugged)

---

## Branch-specific fixes (new — not present upstream or on the fork's master)

- [`cf10308`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/cf103083c97029475552baadd9efa1192318ef52) — StageData/LoadingState: Std.int-coerce preload filter bitmask (hxcpp Dynamic->Int miscompile could zero it and skip preloads)
- [`460d3d3`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/460d3d391aa725f559029a3d50da542be604dc89) — HealthIcon: default to CPU caching, not GPU

- **Preload filter bitmask** now coerced with `Std.int` — stock code read the byte-based
  filter straight off `Dynamic`, which miscompiles on hxcpp and could zero the mask, silently
  skipping stage preloads.
- **Health icons default to CPU caching** — GPU-cached bitmaps null their CPU image, and openfl
  9.5.2's `getTexture` can't re-upload after a texture invalidation, blanking the persistent
  health icons. Icons are tiny, so CPU residency is free.

---

## Backported from master (later perf & bug fixes)

Base-applicable fixes cherry-picked from the fork's newer `master` commits (feature-coupled
ones — note-V2, osu!, mobile, psych_v2, reworked editors — were left out):

- [`5ddcd97`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/5ddcd97ed6430b6b05b06c58c208ac4bd9f9ab3a) — Character: type animOffsets as Float pairs + clamp negative shoot frame index
- [`8b015b4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/8b015b481e909f14a856fd80d4ce97bf17c63bc7) — StageData: guard missing stage-sprite scroll/color fields
- [`4ef752b`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/4ef752bf364e50910faa4fe911e303585253dbc8) — Conductor: skip judgement tiers with an unset hit window
- [`0966be7`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/0966be735c2dff68ba090153e2781a49d424fbd9) — GameplayChangersSubstate: store the resolved option default and type the options array
- [`ec3c9e4`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/ec3c9e49d69dd316ec8333d8df658d9373e84f5a) — DialogueBoxPsych: only stop the music this dialogue started
- [`6d10c64`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/6d10c64377711d9a1b79178c4c6f919eee6ae240) — PlayState: fire pending events on generate (was an inverted guard)
- [`cb7d045`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/cb7d0452929e5bafba0cdd97fb8784e6195ecc0d) — Paths/Alphabet: reuse parsed atlases instead of re-reading the description (perf)
- [`00f48a7`](https://github.com/MeguminBOT/FNF-PsychEngine/commit/00f48a7c4e6f04dc1ec55ef5cf2a5e09c4dc2d6c) — CoolUtil: parse JSON with haxe.Json, falling back to TJSON (perf; base callers only)
