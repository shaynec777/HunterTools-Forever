# HunterTools Classic â€” Era test build

Version **3.1.7**, aligned with Forever on November 6, 2026. This is a separate addon, not a replacement for HunterTools Forever. It is ready for initial in-game testing, not a public stable release.

## Installation

Extract `HunterToolsClassic` from the test ZIP into the Classic Era client's `Interface/AddOns` directory. Fully restart Classic if it was already open. Enable **HunterTools Classic** in the character's AddOns list. There is no FeedomaticToo migration folder in this package.

Open `/ht` or `/htc`. `/ht classicdebug` reports the actual client, interface number and feeding API readiness. Target client: Classic Era 1.15.9 / interface 11509, including Hardcore. The shared Era client also runs Season of Discovery, but its special pet/spell data is not covered by this baseline. Burning Crusade Anniversary and Mists are not supported by this first build.

The source is `classic-port/source/HunterToolsClassic`, settings are `HunterToolsClassicDB`, frame/binding identifiers are separate, and the installed addon folder is `HunterToolsClassic`. No Forever files, saved settings or release archives are changed. `/ht` is retained for familiarity; `/htc` is the explicit Classic alias.

## Changes for Classic

- Private compatibility adapters for pet happiness, diet, loyalty, training points, spell names/ranges/cooldowns, auras and tooltip inspection. Blizzard global APIs are not replaced.
- Era lacks Forever's native `CanPetEatItem` helper. The fallback uses known Classic food IDs, the current pet's localized diet and a conservative item-level eligibility estimate. Unknown foods are never guessed edible; this list may need additions during testing. Happiness gain is not calculated.
- Lowest item level first is the default; the existing high/low option remains available. Food protection and per-pet lists remain enabled.
- Classic Beast Training/craft scans and learned-ability messages supply the hunter's learned ranks. Live pet spellbook abilities are displayed separately.
- Classic pet families, 21 ability groups / 106 referenced ranks, and 297 teaching creatures replace Forever spell/rank/creature records. Reference coverage is partial, particularly resistance rank 5; missing ranks are not reported as nonexistent.
- Player Finder preserves `Name-Realm`, rather than interpreting the second name return as a Forever surname. Unqualified watches match the character name; qualified watches distinguish realms. Targeting revalidates unit GUIDs and requires a click outside combat.
- Only Era aspect IDs are bundled. Forever-only ammunition IDs are excluded. Ammo upgrade/source data and ranged weapon/scope estimates retain their experimental status.
- Mob/player detection and alerts work independently of coordinates. Arrows/map markers are shown only with real public coordinates; ordinary NPC coordinates may be unavailable. No Questie dependency.

## First in-game test

1. On the new hunter, open `/ht`, check the version/name, visit Food, Ammo, Pet Abilities and Finders, and drag/close/reopen panels. A level-1 character having no pet or Feed Pet is expected, not an error.
2. Run `/ht classicdebug` if the menu or feeder is missing. Enable Lua errors with `/console scriptErrors 1`; capture any error text.
3. Check beast-name search and tooltips on a nearby beast. Unknown details should remain unknown. Test Player Finder with a nearby player's exact name and optional partial matching, then click Target.
4. Once level 10 hunter pet quests are complete, tame a pet and test happiness, diet, learned pet abilities, and feeding. Try known edible raw meat/fish and confirm it chooses low-to-high unless changed. Check quest/buff-food protection and depletion warnings.
5. Open Beast Training, then check learned-rank labels. Test Growl disable on dungeon entry when available; Pack replacement waits until Aspect of the Pack is learned. Test combat entry/exit and reload/settings persistence.

Automated tests cover mocked client behavior; actual secure feeding, UI interactions, aura restrictions and all food eligibility require game validation.

## Research evidence

- Classic UI pet frame uses legacy `GetPetHappiness`: https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UnitFrame/Classic/PetFrame.lua
- Vanilla Beast Training uses `GetCraftInfo`, `GetCraftDisplaySkillLine` and `GetPetTrainingPoints`: https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_CraftUI/Vanilla/Blizzard_CraftUI.lua
- Current Classic spellbook API signatures: https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua
- Classic minimap tracking returns a structured table with optional spell ID: https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua
- Pet facts and teaching references: https://www.wow-petopia.com/classic/abilities.php and its linked family pages. Cached factual rank/creature references were retained from the original project's Classic import; no ability descriptions copied.
- Installed Battle.net build metadata identifies Classic Era **1.15.9.70003**, matching the prepared interface 11509. This is separate from Forever's 16001 interface.

Research source snapshots are under `research/`. `validate_classic.py` runs private-adapter, data, startup and adapted feature tests. `package_classic.py` validates and packages only the independent addon directory, checking ZIP contents, hashes and the unchanged Forever source baseline.

October 21 source cleanup: all runtime lookups/links use Classic sources, with Classic family roles/diets/training options from 16 cached Petopia Classic family pages. The copy-link window now offers only Petopia Classic and Wowhead Classic. Original license notices remain unchanged. Track Beasts is confirmed working in game after the missing-spell-ID fallback.

Publication, October 22: submitted as the initial public beta to CurseForge project HunterTools Classic (1760155), file 9291909, for Classic Era 1.15.9. Automatic publication after moderator approval is enabled. Project/file approval was still pending at submission.

October 25 tameability fix: imported explicit Petopia Classic flags for all 622 NPCs on its family/look pages (552 tameable, including two Horde-only; 70 not tameable). Search now includes non-teaching creatures. Exact source links and faction restrictions are shown. New PetopiaTameability.lua module requires a full game restart. Run build-petopia-tameability.py to rebuild the separate edition datasets; --refresh redownloads the sources. The published beta1 ZIP remains unchanged; fixed local preview is HunterToolsClassic-tameability-preview.zip.
