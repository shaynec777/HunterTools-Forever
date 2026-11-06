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
