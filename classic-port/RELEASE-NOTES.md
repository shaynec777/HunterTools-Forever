# HunterTools Classic 3.1.11a

## Bug fixes — 3.1.11a

- Fix Classic's range window remaining at In range / Out of range when Auto Shot reports invalid spell bounds (observed minimum 35, maximum 0).
- Use validated learned-shot bounds when available. Outside combat, retain live shot/follow-distance classification even if numeric bounds are unavailable, restoring Too close / In range / Too far without inventing yardage.
- Carcasses and friendly targets display estimated distance bands without claiming shooting eligibility. In combat, unavailable secondary checks retain the honest Out of range fallback.

## Validation

User confirmed the Classic range window now shows Too close, In range and Too far at the tested positions outside combat. Dedicated regressions cover malformed metadata, missing fallback bounds, corpses, combat restrictions and recovery. Existing settings are preserved.

Includes the 3.1.11 sidebar menus, per-line tooltip controls, green buttons and 80% opaque backgrounds.

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.

# HunterTools Classic 3.1.11

## New in this update

- Sidebar settings navigation groups Feeding, My pet, Wild beasts, Tracking & aspects, Ammunition & weapons, Range & dungeon checks, and Finders in one window. Existing slash commands remain available.
- Direct pet and wild-beast tooltip settings, with per-line controls independent of window settings. Additional beast controls include location, learned-rank labels, training options and reference lines.
- Softer rounded tooltip-style borders, green buttons and 80% opaque menu backgrounds. Embedded pages share the main background to avoid stacked opacity.

## Bug fixes

- Clearer category/page headings and specific enable labels make settings easier to locate. Existing character preferences are retained.

## Validation

User reviewed the new Forever menus and requested the final green-button, 80% opacity styling. Automated navigation, tooltip controls, saved-field independence and combat guards checked. Classic in-game confirmation remains pending.

Thanks to [**AalSupes**](https://www.curseforge.com/members/aalsupes) and [**BluBuryPi**](https://www.curseforge.com/members/bluburypi) for their help testing and improving HunterTools.

# HunterTools Classic 3.1.10

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

# HunterTools Classic 3.1.9

## New in this update

- Reduce background work by filtering unrelated unit events and combining bursts of relevant events into a single refresh.
- Cache quest-food protection and pet ability lists, with event invalidation and loading/recovery retries.
- Avoid rebuilding unchanged aspect/tracking menus and resetting unchanged pet portraits. Keep the half-second live-status and reminder fallback.

## Bug fixes

- Prevent unrelated aura and spellcast activity from repeatedly invalidating inventory and refreshing pet displays.
- Feeding clicks retain immediate validation; settings and existing functionality are preserved.

## Validation

The user played the combined Forever build without observing issues. This does not confirm resolution of the original stuttering report. Classic in-game confirmation remains pending.

# HunterTools Classic 3.1.8

## New in this update

- When multiple tracking abilities are active, the tracking button prefers any active tracker other than Find Treasure. Find Treasure remains the icon when it is the only active tracker.

## Bug fixes

- Prevent active Find Treasure from masking Find Minerals or other active trackers on the floating button. Tracking abilities and their active indicators remain unchanged.

## Validation

Tracking regressions cover both list orders, Treasure-only fallback, and no active tracking. The user confirmed the change in Forever. Classic in-game confirmation remains pending. Existing settings are preserved.

# HunterTools Classic 3.1.7

## New in this update

- Align the Classic version number with HunterTools Forever: both editions now use 3.1.7. Future releases share the Forever version sequence while retaining separate addon packages and settings.
- Includes the feeder text controls from Classic 0.1.0-beta2: Verbose, Simplified (Happy / Not happy), and Off. Unavailable happiness leaves Simplified blank.

## Bug fixes

- No gameplay changes from Classic 0.1.0-beta2; this release synchronizes version metadata. Classic remains on the beta channel while broader Classic testing continues.

Fully restart Classic if updating from beta1 for the NPC tameability module. Existing settings are retained.

# HunterTools Classic 0.1.0-beta2

## New in this update

- Choose Verbose, Simplified, or Off for the text beneath the feeder button in Food > Feeding & alerts. Click Feeder text to cycle through the choices. The choice is saved per character; Verbose remains the default.
- Simplified shows Happy or Not happy. Off hides the text beneath the button while preserving the happiness border and supply count.

## Bug fixes

- Simplified mode leaves the label blank when happiness is unavailable, including during combat, instead of showing Unknown.

## Validation

The user confirmed the new controls and blank fallback in Forever. Classic uses its private happiness adapter and still needs in-game confirmation of this change. Existing settings are retained.

# HunterTools Classic 0.1.0-beta1

## New in this update
Initial Classic Era beta: pet feeding/status, ability and beast search, aspects/tracking, ammo reminders, Growl/Pack dungeon prompts, target/pet-healing range checks and mob/player finders. Independent addon folder and settings.

## Bug fixes
- Learned tracking fallback fixes missing Track Beasts.
- Classic realm-aware player names and Classic Petopia/Wowhead sources.
- Improved range fallbacks; uncertain out-of-range direction stays explicit.
- Low-to-high food order is the default, with a high-to-low toggle.

## Compatibility and validation
Classic Era 1.15.9 (11509); Hardcore shares this client. SoD-specific data, TBC and Mists are not validated/supported by this package. All 25 Lua regression suites and package integrity checks passed. Track Beasts confirmed in game; broader feeding, later-level and combat testing remains pending. Weapon/scope comparisons remain Experimental. Exact NPC navigation depends on available public coordinates. Install HunterToolsClassic and fully restart WoW.
