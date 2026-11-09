# HunterTools Classic

A configurable hunter toolkit for **WoW Classic Era**, with feeding, pet information, ammunition reminders, tracking, dungeon checks and nearby-unit finders.

**Current beta: 3.1.11a.** Track Beasts has been confirmed in game; feeding, later-level features and combat behavior still need broader Classic testing. This is a separate addon with its own folder and saved settings.

## Current update — 3.1.11a

## Bug fixes — 3.1.11a

- Fix Classic's range window remaining at In range / Out of range when Auto Shot reports invalid spell bounds (observed minimum 35, maximum 0).
- Use validated learned-shot bounds when available. Outside combat, retain live shot/follow-distance classification even if numeric bounds are unavailable, restoring Too close / In range / Too far without inventing yardage.
- Carcasses and friendly targets display estimated distance bands without claiming shooting eligibility. In combat, unavailable secondary checks retain the honest Out of range fallback.

## Validation

User confirmed the Classic range window now shows Too close, In range and Too far at the tested positions outside combat. Dedicated regressions cover malformed metadata, missing fallback bounds, corpses, combat restrictions and recovery. Existing settings are preserved.

Includes the 3.1.11 sidebar menus, per-line tooltip controls, green buttons and 80% opaque backgrounds.

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.

## Classic toolkit

Feeding, per-pet food lists, quest-food protection, hunger and supply alerts, pet status, ability teachers, beast search, aspects and tracking, ammo reminders, dungeon prompts, target range and nearby mob/player watches. Uses Classic-specific APIs, reference links and saved settings.

## Commands and controls

Open **/ht** or **/htc** for the main menu.

- **/ht foods**: Food catalog and Feeding & alerts.
- **/ht abilities**: Pet abilities and teaching animals.
- **/ht beastdetails**: Inspect a targeted beast or open name search. Add a name to search directly.
- **/ht tracking** and **/ht aspects**: Floating buttons and reminder settings.
- **/ht petsettings**, **/ht petalerts**, **/ht ammo** and **/ht weapons**: Individual tool settings.
- **/ht mobfinder** and **/ht playerfinder**: Nearby-unit watch lists; add a name to begin watching.
- **/ht classicdebug** and **/ht rangedebug**: Troubleshooting information.

Shift-left-drag unlocked windows to move them. Feeding and targeting require a click or keypress. A new hunter needs to complete the level-10 pet quests and learn Feed Pet before using the feeder.

## Installation

Install the **HunterToolsClassic** folder into your Classic Era client's Interface/AddOns directory and fully restart the game. Enable **HunterTools Classic** in AddOns. Settings are stored separately in HunterToolsClassicDB; there is no settings-migration companion addon.

The first beta targets **Classic Era 1.15.9 / interface 11509**. Hardcore uses the same client. Season of Discovery-specific pet/spell data is not validated. Burning Crusade Anniversary and Mists of Pandaria Classic are not supported by this package.

## Data, estimates and testing limits

Pet facts come from [Petopia Classic](https://www.wow-petopia.com/classic/abilities.php), its family pages and your local observations. [Wowhead Classic](https://www.wowhead.com/classic) links are provided for further research. The bundled reference covers 21 ability groups, 106 ranks and 297 teaching creatures; it is partial, including gaps in some top resistance ranks. Open Beast Training to update cached hunter learned ranks. Unknown information is not treated as a confirmed absence.

Classic food eligibility uses known food IDs, the pet's localized diet and an item-level estimate. Unknown foods are not guessed edible, and happiness gain is not calculated. Check food protections before feeding valuable ingredients.

**Ranged weapon comparisons and scope previews are Experimental.**

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval.

The estimate includes live ranged AP, ammo, scope and retained damage/speed bonuses. It excludes armor, misses, critical hits, rotations, pet damage, procs and unsupported stat/talent effects. It is a stationary Auto Shot estimate, not total hunter DPS. English weapon tooltip text is currently required.

Range displays are approximate bands, not exact yard measurements. Detection depends on units the client exposes; this is not a zone-wide scanner. Arrows and private map markers require genuine public coordinates, which ordinary NPC detections may not provide. A visible targeted nameplate can receive a brief highlight. No Questie dependency is required.

All 25 automated Lua 5.1 suites, syntax, TOC references, ZIP integrity and source-byte checks passed. Mock checks do not replace in-game validation. Please report the tool used, what happened and any Lua error.

## Credits

Original feeding engine: FeedPetForever by Gideon (MIT licensed); original notices are retained. Original Feed-O-Matic concept: Gazmik Fizzwidget. Adaptation and enhancements: OpenAI Codex, directed and tested by the user. The approved hunter multitool logo is original AI-generated project artwork. No affiliation or endorsement by Blizzard or the reference sites is implied.

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.
