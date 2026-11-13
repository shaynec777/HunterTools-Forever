# HunterTools Forever 3.1.11a

## Bug fixes

- Restore health and focus bar fills and numeric labels when Forever returns restricted resource values. Values go directly to supported native display widgets.
- Keep enabled health and focus bars updating during combat. Other pet details retain their combat pause.
- Clear stale resource fills when data becomes unavailable. Existing settings are preserved.

## Validation

The user confirmed the corrected bars look better in Forever. Focused Lua 5.1 tests cover opaque-value display, combat updates, zero/missing values, native setter failures, recovery, and existing pet-status behavior.

This corrective release updates Forever only. HunterTools Classic remains at its existing 3.1.11a release.

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.

# HunterTools Forever 3.1.11

## New in this update

- Sidebar settings navigation groups Feeding, My pet, Wild beasts, Tracking & aspects, Ammunition & weapons, Range & dungeon checks, and Finders in one window. Existing slash commands remain available.
- Direct pet and wild-beast tooltip settings, with per-line controls independent of window settings. Additional beast controls include location, learned-rank labels, training options and reference lines.
- Softer rounded tooltip-style borders, green buttons and 80% opaque menu backgrounds. Embedded pages share the main background to avoid stacked opacity.

## Bug fixes

- Clearer category/page headings and specific enable labels make settings easier to locate. Existing character preferences are retained.

## Validation

User reviewed the new Forever menus and requested the final green-button, 80% opacity styling. Automated navigation, tooltip controls, saved-field independence and combat guards checked. Classic in-game confirmation remains pending.

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.

# HunterTools Forever 3.1.10

## New in this update

- Reduce repeated inventory and quest-protection scans by tracking specific missing item IDs. Unrelated item-information events no longer reset the stable inventory snapshot or keep loading retries running indefinitely.
- Cache resolved quest food names and avoid idle target-highlight updates. Preserve immediate feeding validation and retries for genuinely missing data.
- Clean up pet-status separators, labels and the compact ability list. Full command/stance information remains in the tooltip.

## Bug fixes

- Fix the entry-loading loop that repeatedly rescanned ready inventory. Retain quest-food protection and item-loading safeguards.
- Remove temporary timing diagnostics and counters from the shipped addon.

## Validation

The user's Forever performance sample dropped from 5.31 to 0.15 inventory scans per second after the loop fix. This is one comparison, not a universal performance guarantee. Classic shares the affected logic and receives the same fixes; Classic in-game confirmation remains pending.

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.

# HunterTools Forever 3.1.9

## New in this update

- Reduce background work by filtering unrelated unit events and combining bursts of relevant events into a single refresh.
- Cache quest-food protection and pet ability lists, with event invalidation and loading/recovery retries.
- Avoid rebuilding unchanged aspect/tracking menus and resetting unchanged pet portraits. Keep the half-second live-status and reminder fallback.

## Bug fixes

- Prevent unrelated aura and spellcast activity from repeatedly invalidating inventory and refreshing pet displays.
- Feeding clicks retain immediate validation; settings and existing functionality are preserved.

## Validation

The user played the combined Forever build without observing issues. This does not confirm resolution of the original stuttering report. Classic in-game confirmation remains pending.

# HunterTools Forever 3.1.8

## New in this update

- When multiple tracking abilities are active, the tracking button prefers any active tracker other than Find Treasure. Find Treasure remains the icon when it is the only active tracker.

## Bug fixes

- Prevent active Find Treasure from masking Find Minerals or other active trackers on the floating button. Tracking abilities and their active indicators remain unchanged.

## Validation

Tracking regressions cover both list orders, Treasure-only fallback, and no active tracking. The user confirmed the change in Forever. Classic in-game confirmation remains pending. Existing settings are preserved.

# HunterTools Forever 3.1.7

## New in this update

- Choose Verbose, Simplified, or Off for the text beneath the feeder button in Food > Feeding & alerts. Click Feeder text to cycle through the choices. The choice is saved per character; Verbose remains the default.
- Simplified shows Happy or Not happy. Off hides the text beneath the button while preserving the happiness border and supply count.

## Bug fixes

- Simplified mode leaves the label blank when happiness is unavailable, including during combat, instead of showing Unknown.

## Validation

The user confirmed the new controls and blank fallback in Forever. Classic uses its private happiness adapter and still needs in-game confirmation of this change. Existing settings are retained.

# HunterTools Forever 3.1.6

## New in this update

- Clearer colored pet-status and animal tooltips, preserving learned-ability indicators.
- Updated NPC-specific Petopia tameability, including untameable and faction-restricted creatures and exact source links.
- Display the addon as HunterTools Forever while retaining existing folder names, commands and settings.

## Bug fixes

- Skip interaction-distance checks during combat and tolerate unavailable checks outside combat. Public spell-range results remain usable; unknown distances remain unknown.
- New or invalid food-order settings default to lower-level food first; existing high/low preferences are retained.

## Updating and validation

Install HunterTools and FeedomaticToo from the ZIP and fully restart Forever for the tameability module. Existing character settings are preserved. Classic is a separate edition and is not included in this release.

Focused Lua 5.1 range, Mend Pet and pet-alert regressions passed. The user reports the currently installed build is functional. This is not exhaustive in-game coverage. Weapon comparisons and scope previews remain Experimental; existing data-source limitations remain documented.

# HunterTools 3.1.5

## New features

- Mob Finder and Player Finder, accessible from the new Finders section of the main menu or `/ht mobfinder` and `/ht playerfinder`.
- Saved watch lists, optional partial-name matching, sound/screen alerts and a click-to-target detection popup. Player targeting supports Forever surnames.
- Brief highlight on the targeted unit's visible nameplate. Direction arrows and private map markers require genuine public location data; ordinary detections commonly provide none. No Questie dependency.
- Current pet details can display learned abilities from the live pet spellbook, with independent window and mouseover settings.

## Fixes and compatibility

- Include Sonic Blast in Bat family training options, with Blizzard/Petopia source labeling. This does not claim that every wild bat teaches it or assign unknown ranks.
- Clarify that weapon comparisons assume stationary Auto Shot, including the new 0.5-second standing requirement.
- Reviewed October 15 changes to Dismember, Sonic Blast and Mine!: bundled ability records store spell identities and teaching references, not outdated damage, duration or cooldown descriptions. Pet expertise/crit changes do not require changes to our Auto Shot-only estimate.
- Growl detection and disabling on instance entry confirmed working in game after the update.

## Upgrade and limits

Install both addon folders from the ZIP and fully restart WoW for the new finder modules. Existing character settings are retained.

Player targeting with a full Forever name is confirmed in game. Broader Pack behavior, finder combat transitions, settings persistence and navigation on coordinate-bearing rare/event markers still need in-game coverage. Targeting requires clicking the button and is unavailable during combat.

# HunterTools 3.1.4

## New in this update

- Compact aspect and tracking lists open beneath their floating buttons on right-click. Green markers identify active choices; opening either list closes the other. Automatic reminder dialogs remain separate.
- Favorite aspects and tracking abilities with the star beside each choice. Favorites save per character and appear first; aspect favorites survive learning a higher rank. Favorites can be changed outside combat.
- Native spell tooltips on aspect/tracking choices, aspect reminder choices, and the active spell on each floating button.
- Beast details and name search for every class. `/ht beastdetail` or `/ht beastdetails` inspects a targeted wild beast, or opens search when no suitable beast is targeted. Add a full or partial name to search directly; `/ht beastsearch` also opens search.
- Search the bundled beast references and your character's journal by name, with paged results and distinct NPC identities for beasts sharing a name. Detail windows include a search box and preserve data-source labels and unknown fields.
- Pet Abilities includes a beast-name search that displays results and scrollable details inside the ability browser, with optional portraits and a Back control. Selecting an ability or clearing the beast search returns to teaching animals.

## Bug fixes and refinements

- Keep Pet Abilities searches and details in the ability browser rather than switching to the standalone beast window.
- Give the embedded beast-details panel a solid dark background and raise it above the ability controls for readability.
- Non-hunters can inspect beast information without enabling hunter display options; hunter learned-ability labels are omitted for other classes. HunterTools itself must be enabled for that character.

## Existing features and limits

The aspect button, pet healing-range warning and native low-health/death alerts from 3.1.2 remain included. When Forever restricts pet health, the native low-health visual still works, but low-health sound/chat and timed repeats are unavailable. Death alerts work separately.

Ranged weapon comparisons and scope previews remain **Experimental**.

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

The estimate includes character ranged AP, ammo, scope and retained live damage/attack-speed bonuses. It excludes armor, misses, crit, rotations, pet damage, procs and unsupported stat/talent effects. Pet data retains labeled community/Classic fallbacks and local observations; unknown facts remain unknown.

## Updating and validation

Install both addon folders from the ZIP into Interface/AddOns and fully restart WoW to load the new SpellDropdown.lua module. Existing settings are retained. Enable HunterTools for each character that will use beast details or search, including non-hunters.

The user confirmed aspect/tracking menu behavior, beast details on a druid, and readability of the embedded details panel after the opacity/layering fix. Automated Lua 5.1 checks cover the feeding engine and all 29 Lua regression files, including name search, pagination, source precedence, duplicate names/NPC IDs, standalone command aliases, embedded navigation, tooltips, favorite sorting/rank changes, secure mutual menu exclusion and combat guards. All addon Lua files, TOC references, ZIP integrity and addon-only root folders are checked during packaging.

Existing Pack/combat aspect switching and beast journal collection retain their previously documented need for broader in-game testing. Search uses available local/reference data and does not reveal missing Beast Lore information. Favorites persistence and less-common UI/combat sequences still benefit from broader in-game feedback.
