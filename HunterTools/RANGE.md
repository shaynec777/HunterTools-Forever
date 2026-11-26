# Forever combat range labels

For a living, publicly attackable target, Auto Shot in-range is shown directly. If Auto Shot is out of range and its verified maximum is at least 28 yd, a public follow-distance check distinguishes Too close from Too far. Friendly, dead or unreadable-target interaction checks remain disabled in combat. Missing, secret or failed native results remain Range unavailable. No spell is cast, no target is changed and no range values are persisted across rulesets. Existing half-second updates are reused.

Primary implementation reference: WeakAuras/LibRangeCheck-3.0, checkers_Interact and InCombatLockdownRestriction in https://raw.githubusercontent.com/WeakAuras/LibRangeCheck-3.0/master/LibRangeCheck-3.0/LibRangeCheck-3.0.lua (checked November 24, 2026). This upstream explicitly detects Forever and guards combat checks on non-attackable targets. No library code or dependency is bundled. Native spell-range API reference: https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua .

Regression coverage includes living hostile close/in/far, friendly/dead/unreadable targets, secret or rejected distance queries, public Auto Shot, and out-of-combat recovery. Live Forever combat verification remains pending. Classic Era is unchanged by this fix.


## Optional measured distance (3.2.22)

Range settings includes Measured distance, disabled by default. It reuses the existing range-window refresh and makes no distance/position queries while disabled. A checked native UnitDistanceSquared result is preferred; matching valid UnitPosition coordinates provide a straight-line fallback. Missing, restricted, secret or invalid results retain the existing distance bands. Measured distance does not change attack-range classification, and large target hitboxes can make the two differ. No new timer or saved character coordinates are added. Native availability on live targets, including combat, still needs in-game testing.


### Distance query safeguards (3.2.23)

Successful readings refresh at most once per second and are cached only for the same public target GUID. Unavailable queries retry after five seconds. A query taking at least 2 ms pauses for 60 seconds; the first slow native call cannot be interrupted. Target coordinates are checked before player coordinates. Disabled measurement makes no distance queries. `/ht perf distance` prints cumulative, saved per-query counts, total/max milliseconds, unavailable results, errors and slow-call counts, without requiring a performance session. Forever diagnostics and runtime state respect character/ruleset boundaries. Timings include small clock/pcall overhead; live attribution is pending the next test.


### Range window work sharing (3.2.24, Forever)

Attack and Mend Pet range checks remain live on the existing half-second updater. Auto Shot metadata and learned Mend Pet ranks are cached for up to five seconds, invalidated on spell changes, world entry and player aura changes. Target animal details (including empty results) reuse a two-second cache keyed by public target GUID and display settings. Target changes, target aura/flags/level events, bag/item events, player spell casts and pet ability events invalidate details. Combat immediately hides animal details and clears their cache; leaving combat rebuilds them. Character/ruleset transitions clear all new caches. No new timer, saved position or inventory snapshot is added. Expanded temporary performance instrumentation separates detail work, food counts, status and healing checks. Watch for stale Beast Lore details, bag food counts or learned heal ranks; missed events recover via the short expiry.


### Range rendering diagnostics (3.2.25, Forever)

Temporary performance sessions now time portrait updates, detail text/layout and status/visibility stages, plus individual native calls (portrait texture, text, string height, layout, color/alpha, Show/Hide and range unit/spell queries). The saved performance report includes every range render/native row beyond the ordinary top ten; spike entries preserve nested attribution and self time. These clocks/wrappers run only during an active `/ht perf start 120` session. No new timer is added. The native Show call remains unchanged for diagnosis. Instrumentation adds overhead; nested inclusive totals must not be added. Test combat, target switching, movement and animal details, then reload after the session completes.


### Shared animal inventory and lore (3.2.26, Forever)

AnimalFoodInventory supplies one transient item-count/item-level summary to all animal diets and levels. Metadata is read once per food ID per summary, including duplicate stacks. Bag/world events invalidate it; only pending food IDs invalidate on item-load completion. Complete summaries recover from missed events after 30 seconds, incomplete summaries retry after two seconds. Per-diet text caches are bounded. Feeding click validation is unchanged. Beast journal observation and animal details share a two-second public-GUID-keyed ReadBeastLore cache, including unavailable results. Target changes, relevant aura events, successful player casts and world entry invalidate lore. Combat performs no lore reads. Both caches reset at character/ruleset changes and are never persisted. Temporary performance tests now also measure inventory building, lore reading, beast observation and record merging. Test looting/feeding/splitting stacks, different animal diets, and freshly cast Beast Lore.


### Complete saved animal timing breakdown (3.2.27)

Saved performance reports always include AnimalFoodInventory, AnimalFoodCounts, ReadBeastLore, AnimalLore, ObserveBeast, BeastRecord, TargetPetDetails and RangeTargetDetails, independent of the top-ten list. Each row includes call count, total, average, peak and self milliseconds; unused functions explicitly show zero calls. Existing opt-in instrumentation and timers are unchanged.


### Feeding inventory-only invalidation reuse (3.2.28, Forever)

Combat exit/happiness callbacks do not themselves dirty food inventory, but can inherit bag/lock invalidations. For inventory-only invalidations, EnsureFoodScan now compares public item IDs, counts, locks and slot positions against a complete previous feeding scan before repeating eligibility/protection/item metadata work. It still walks slot data; it skips FindFood only when every slot matches. Changed pet, quest/rules/settings, pending/locked/loading inventory and explicit feed clicks retain full scans. Hard invalidations dominate mixed event bursts. Existing half-second coalescing is retained. Snapshots are transient and cleared across character/ruleset transitions. The saved food breakdown includes EnsureFoodScan and FoodInventoryMatches to measure comparison cost. Test looting, feeding, locks, pet changes and quest-food protection.


### Pet tooltip resource display (3.2.29, Forever)

Health/focus tooltip lines now use the existing display-safe raw resource reader. Public values retain the ordinary percentage string. Restricted values pass directly to the named tooltip font string SetFormattedText, without Lua arithmetic, concatenation, caching or serialization. Missing APIs, failed reads, unsupported unnamed tooltips or formatting failures retain the unavailable fallback. Paused/missing-pet views do not request resources. No new timers or inventory scans.
