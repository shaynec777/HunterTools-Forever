# Ranged weapon catalog (3.2.9)

Open **Ammunition & weapons â†’ Weapon catalog & suggestions**, or `/ht weaponlist`.
Filter guns, bows, crossbows and crafted/instance/vendor sources; search names or sources.
Separate reputation and PvP filters select those vendor purchases. Vendor details
include seller names, zones, faction, stock and item/currency/gold costs. Full item
requirements are shown separately, including reputation and PvP rank gates.

**Suggested for my level** selects the highest base weapon DPS among entries
matching your level, faction, type/source and search filters. It jumps to the
entry and shows its source gates and equipped-weapon comparison. It does not
assume you meet reputation/rank requirements or own the required currency, and
does not model attack-power effects, procs or proficiency when ranking suggestions.
It can therefore suggest a longer-term acquisition target rather than an item
you can immediately buy. A suggestion need not be an upgrade over equipped gear;
the comparison displays the difference.
Entries sort by weapon type, required level and name. Select a row for the full
stat snapshot and acquisition source; hover for the client's current item tooltip.

Base average damage and weapon DPS compare against the equipped weapon, preferring
live cached client stats when available. The existing experimental Auto Shot model
also appears when the item is usable and its normal ammo/stat checks succeed. It
uses current buffs/ammo and selected scope preview; it does not simulate procs,
crit, misses, armor, weapon-specific talents, quivers or proficiency. Future items
still show the raw base comparison without pretending the player can equip them.

Level-up popups are opt-in on the catalog page. Choose a weapon/source filter and
click **Use current type/source for alerts**. Alerts fire only when crossing a
required level during play, coalesce skipped levels and defer until combat ends.
Login and zoning do not trigger catch-up popups. Required level does not imply
access to a dungeon, raid, recipe or profession requirement.

## Data and limits

Independent snapshots collected 2026-11-15 from Wowhead's visible category source
lists and edition-specific public item tooltips:

- [Forever guns](https://www.wowhead.com/forever/items/weapons/guns),
  [bows](https://www.wowhead.com/forever/items/weapons/bows),
  [crossbows](https://www.wowhead.com/forever/items/weapons/crossbows).
- [Classic guns](https://www.wowhead.com/classic/items/weapons/guns),
  [bows](https://www.wowhead.com/classic/items/weapons/bows),
  [crossbows](https://www.wowhead.com/classic/items/weapons/crossbows), with
  **WoW Classic â€“ Classic Era â€“ All Phases** selected (not Season of Discovery).

94 Forever and 91 Era records have listed sources: the original 45/53
crafted/instance records plus 49/38 vendor records. Vendor-page evidence is saved
independently in `data/ranged-weapons/vendor-browser.json`; seller costs use explicit
currency and gold/silver/copper units. Two quest-associated Verdant Keeper's Aim
listings have no verified seller table and are excluded.
Unconfirmed Forever records are excluded. This is a catalog of listed sources,
not a claim to enumerate every generic world-drop green that might drop inside
an instance. Pure quest rewards remain outside this catalog.
Named NPC/chest names are retained without automatically calling every NPC a boss.
Random zone drops and generic boss drops are labeled as such; the latter do not
yet have verified boss names. No inherited Classic sources are asserted for
Forever. Some weapons have additional sources beyond the category's primary one.

Catalog stat snapshots can differ from the client's current tooltip; live item
data takes precedence for comparisons. No Questie or other addon is required.

PvP rank gates are supplemented from Blizzard's separate edition documentation:
[Classic rank rewards](https://worldofwarcraft.blizzard.com/en-us/news/23221132)
and [Forever PvP progression](https://worldofwarcraft.blizzard.com/en-us/news/24303316).
Legacy rank-14 records can coexist with current-season variants in the public
database; confirm season/vendor availability in game. Classic WSG bows use the
Revered requirements documented by the [Warsong reputation guide](https://www.wowhead.com/classic/guide/warsong-outriders-warsong-gulch-reputation-wow-classic)
and faction item pages; these are not copied from Forever. Merchant discounts,
stock and requirements can change. Shared legacy IDs may carry misleading SoD
badges on the website; those badges are stripped, and only IDs from the Era-filtered
category list are accepted for Classic.

To regenerate: run `data/ranged-weapons/build_ranged_catalog.py`, then
`data/ranged-weapons/add_vendor_weapons.py`. Item/source research snapshots are
retained for review; neither addon requires network access.


3.2.8: Suggested for my level automatically selects the equipped gun/bow/crossbow
category before applying the existing source/search filters. If equipped metadata
is unavailable, the current category is retained with a chat explanation. The
list remains sorted by type, required level, then name, rather than by power.
Every row and its details explicitly label Vendor, Crafted or Instance drop;
reputation and PvP vendors have distinct labels. Text labels accompany colors.


3.2.9: A level box beside Suggested defaults to the player's level whenever the
page opens. Suggested limits the displayed list to required levels 1 through the
chosen level (1-60), applies faction access, and selects the strongest base-DPS
match for the equipped weapon category and source/search filters. Level eligibility
does not imply reputation, rank, currency or proficiency requirements are met.
Full list removes the level/faction limit and clears the search while preserving
weapon category and source filter. The list remains ordered by required level.
Source is the UI term for Vendor, Crafted and Instance drop. Detail text highlights
required level, DPS, damage, source type, seller/boss, location and requirements;
secondary notes are muted and acquisition entries are separated for readability.
