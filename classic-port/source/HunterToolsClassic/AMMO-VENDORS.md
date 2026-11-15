# HunterTools Classic ammo vendors — 3.1.12

- Find ammo sellers for your equipped weapon, level and faction without another addon.
- Use **Nearest vendor for my level** in the Ammo config header to locate a seller of the best ordinary ammo tier you can use.
- Click **Mark nearby ammo seller** in chat reminders to mark a local seller, or the nearest known suitable seller on the same continent.
- Compact world-map and minimap markers clear when you speak to the selected NPC. Known shop names appear on map labels and minimap tooltips.
- Locally observed shop stock updates the bundled reference. Distances are straight-line estimates, not travel routes.

Open `/ht ammovendors` or Ammunition & weapons > Ammo sellers. Stock/upgrade reminders can be disabled independently of manual vendor lookup. Upgrades only and Include restocking control the seller list.

The standalone Classic data contains 111 ordinary-ammo sellers with outdoor spawn coordinates. It is a Classic reference, not a live inventory scan. It is independent of the other edition and excludes reputation/currency purchases. Cities and zones are resolved through Era's native map transforms. Native minimap zoom widths provide the Era radius fallback; no other map library is loaded. Combat suppresses markers/actions. Missing coordinates do not produce invented distances. Matching NPC gossip/merchant interactions and Clear marker remove both destinations.

Known shop names are building-name references from the official World of Warcraft Atlas (https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_hr.pdf). Local visits preserve these and refresh complete ordinary-ammo stock; incomplete item links preserve the prior observation. Local shop position means the player's position at the counter.

## Data source and license

AmmoVendorData.lua is a modified factual subset of CMaNGOS Classic DB, GPL-3.0. Source: https://github.com/cmangos/classic-db/blob/master/Full_DB/ClassicDB_1_12_1_z2815.sql.gz . Retained notices: AMMO-VENDOR-DATA-LICENSE.txt and AMMO-VENDOR-DATA-COPYRIGHT.md. Game names/materials belong to Blizzard or its licensors. Modifications filter unconditional ordinary-ammo stock, join vendor templates to named NPCs/outdoor spawns, deduplicate NPCs, add faction access and named-shop references, and emit editable Lua source. The preferred JSON data and generator are included in the repository as classic-port/ammo-vendor-classic-source.json and classic-port/build-ammo-vendor-data.py. This data's GPL notices are separate from the original MIT addon code. No game client modifications, servers or other addons are bundled.

The Classic port passes automated Lua 5.1 checks but still needs live Classic map/minimap verification. World-map names/stock/locations may change; no reference guarantees current availability.
