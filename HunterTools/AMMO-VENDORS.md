# Ammo sellers â€” local development build, November 15, 2026

Open `/ht ammovendors`, or Ammunition & weapons > Ammo sellers. Upgrade advice also has a Find nearby ammo sellers button. The finder works independently of the ammo reminder and upgrade-advice enable settings.

The default view lists usable upgrades in the current zone. Include restocking lists lower/equal damage ammo; All known zones provides alternatives elsewhere. Local results are ordered by straight-line distance when player/map size data is available, then ammo damage. This is not route distance.

Selecting a seller opens the world map with a labeled ammo marker owned only by HunterTools. Gossip/shop interaction with the matching Creature NPC ID clears it; other NPCs do not. Clear marker removes it manually. It does not alter user waypoints or other addons' pins. Marker destinations are session-only. Map zoom/pan refreshes the pin; combat suspends display and interaction handling.

Chat ammo-stock and upgrade/depletion reminders include **[Mark nearby ammo seller]**. Clicking it rechecks your current weapon, level, carried ammo and zone. It marks a known local usable upgrade, or a restocking option when no upgrade is known. If none is known in this zone, it suggests and marks the closest known usable seller on the same continent, showing their name, zone and approximate straight-line distance. It does not compare distances across continents or guess when world coordinates are unavailable. The current-zone seller list similarly suggests the nearest matching seller when empty, respecting Upgrades only versus Include restocking. If no comparable seller is known, it opens the list for manual browsing. Chat data cannot supply arbitrary coordinates. Combat clicks ask you to try after combat. Banner text stays plain text.

## Independent Forever data

No Questie, QuestieDB, TomTom, other addon, account or network access is required at runtime. No Classic fallback is loaded or included. AmmoVendorData.lua bundles **128 distinct sellers** from Wowhead's **Forever** item-specific Sold by tables, covering ordinary Rough/Sharp/Razor/Jagged Arrows and Light/Heavy/Solid Shot/Accurate Slugs. **126 have coordinates** from their own Forever NPC map pins. Rarck and Jonivera Farmountain are listed by Wowhead but lack map pins, so the finder omits them until a local shop visit supplies a location. New Forever zones use the client's map tree to resolve native map IDs.

The data includes new Forever vendors in Riverglades, Mount Hyjal and Zephras Isle, and the faction access shown in the Forever listings. It does not reuse Classic stock or spawn coordinates. The source is a community database, not a live scan: **Forever reference** does not mean HunterTools verified it in your game. Recorded positions may represent one of several spawns or a wandering vendor's route. Exact current availability, price, death state and access are not guaranteed. Reputation/currency purchases and engineered ammo are outside this finder.

New/changed ordinary-ammo vendors are learned locally from shops you visit, per character. A visited location is your position at the counter, not the NPC's exact coordinates. Complete loaded shops replace older stock; incomplete links leave the prior observation intact. Sold-out limited stock is omitted until a later visit sees it available. Your shop observations take precedence over the bundled reference.

## Sources and reproducibility

Factual stock and faction access: https://www.wowhead.com/forever/item=2512#sold-by , https://www.wowhead.com/forever/item=2515#sold-by , https://www.wowhead.com/forever/item=2516#sold-by , https://www.wowhead.com/forever/item=2519#sold-by , https://www.wowhead.com/forever/item=3030#sold-by , https://www.wowhead.com/forever/item=3033#sold-by , https://www.wowhead.com/forever/item=11284#sold-by , https://www.wowhead.com/forever/item=11285#sold-by . Each NPC's individual Forever URL and coordinates are recorded in `ammo-vendor-forever-source.json` in the source repository. All eight visible item tables and all 128 NPC pages were checked on November 15, 2026. Names and coordinates are factual reference data; game names/materials belong to Blizzard or its licensors. Credit: Wowhead Forever.

`build-ammo-vendors.py` compiles the archived visible table/map facts into the editable bundled Lua table; it does not use another addon or hidden browser state. C_Map world-map support is documented in https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua . Focused Lua 5.1 tests exercise stock/level/faction filtering, local data overrides, missing/incomplete/zero stock, marker ownership and matching NPC interactions, chat links, combat guards and sidebar navigation. Live rendering still needs user verification.

## Minimap destination

A compact cyan-bordered ammo icon marks the selected seller on the minimap even with the world map closed. Nearby sellers appear at their location; distant sellers clamp to the inner edge to show direction. Rotating minimaps account for player facing. Hover for name, straight-line distance and edge status. Missing/restricted position, radius or facing hides uncertain markers. Combat hides the marker until combat ends. Speaking to the matching NPC or clearing the destination removes both markers.

## Named shops

Where a named shop is recorded, the world-map label includes a compact second line and the minimap hover includes the shop name. Unknown shops do not get invented names. Nine curated NPC-to-shop associations are maintained in `ammo-vendor-shops.json`, including Fizzlespinner's General Goods for Bryllia Ironbrand. Source: official World of Warcraft Atlas regional index, https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_hr.pdf . These are original-world building-name references, not independently confirmed Forever building labels; stock and coordinates still come exclusively from the Forever listings and local visits. Shop names survive local stock updates.

## Current-level ammo button

The Ammo config header has a Nearest vendor for my level button, visible on both ammo tabs. It identifies the highest-DPS ordinary vendor ammo usable at your current level for the equipped bow/crossbow or gun, then finds the nearest known same-continent seller of that tier. Carried ammo does not need to be depleted or worse. It prints the item, seller, zone and straight-line distance and marks the destination on both maps. If that tier cannot be located, it explains this rather than silently choosing lower-tier ammo.
