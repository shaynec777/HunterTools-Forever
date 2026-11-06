# HunterTools Classic

A configurable hunter toolkit for **WoW Classic Era**, with feeding, pet information, ammunition reminders, tracking, dungeon checks and nearby-unit finders.

**Initial beta: 0.1.0-beta1.** Track Beasts has been confirmed in game; feeding, later-level features and combat behavior still need broader Classic testing. This is a separate addon with its own folder and saved settings.

## New in this update

- Feeder text: choose Verbose, Simplified (Happy / Not happy), or Off in Food > Feeding & alerts. Simplified leaves unavailable happiness blank. The colored border remains visible.

- Classic Era compatibility for pet happiness, diet, loyalty, training points, Beast Training, spellbooks, auras and tooltips.
- One-click pet feeding, per-pet allowed/blocked food lists, quest-food protection, hunger alerts and supply warnings. Food defaults to lowest item level first; switch between low-to-high and high-to-low in **Food > Feeding & alerts**.
- A movable pet-status window and own-pet mouseover tips, including learned abilities from the current pet's spellbook.
- Pet ability browser, teaching-creature references, beast-name search and a local observation journal.
- Aspect and tracking buttons with right-click lists, active markers, favorites and native spell tooltips. Learned profession tracking is included.
- Ammo stock reminders and optional upgrade advice.
- Dungeon prompts to disable Growl autocast and replace your own Aspect of the Pack, through your explicit click outside combat.
- Target range estimates and a Mend Pet range warning when that spell is learned.
- Mob Finder and Player Finder with saved watches, optional partial matching, private alerts and a click-to-target popup.

## Bug fixes and Classic refinements

- Track Beasts remains selectable when minimap tracking rows omit a spell ID or an inactive tracking spell.
- Classic player names retain their realm instead of treating it as a surname.
- All pet reference links use **Petopia Classic** and **Wowhead Classic**. The copy-link window has one button for each source.
- Range checks try native, legacy, action-button and learned-shot results. A known range failure remains **Out of range** when its direction cannot be established.

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
