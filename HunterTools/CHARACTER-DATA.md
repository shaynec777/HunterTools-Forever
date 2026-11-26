# Forever character-data isolation

HunterTools has no saved inventory/bank snapshot database: food and ammo quantities come from live bag scans. UI controls, colours, positions, alert preferences and static catalogs remain shared. This change applies to Forever only; Classic Era retains its separate addon and database.

Saved character-derived data is routed into HunterToolsDB.characterRulesetsV1, keyed by the exact Hardcore/RP/PvP rule flags plus the public player GUID. This covers pet food profiles/feeding history, learned pet abilities, discovered foods/ammo, last equipped ammo, observed vendors, remembered vendor raid-mark identity, beast journal records, mob/player watches and saved diagnostics. General food allow/block defaults remain preferences; per-pet lists are character data.

Rules are feature-detected via C_GameRules.IsGameRuleActive and Enum.GameRule. A missing, secret or failed rule query or unavailable player GUID never falls back to PvE or a display-realm/name key. That session uses temporary, nonpersisted character data until identity can be verified. No temporary observations are promoted into a verified profile.

Existing unstamped character records remain untouched at their original root locations, unassigned and excluded from active reads. Their original ruleset cannot safely be inferred. They are not deleted or silently attributed to the first character that loads. Learned pet data and observations rebuild from the current client. No automatic import of unassigned records is performed.

A context listener loads before feature modules. On world entry, game-mode updates or combat recovery, context changes clear live bag/quest/pet/ability/comparison caches, queued feed notices, navigation and finder results. Captured settings views resolve scoped fields dynamically, while shared preferences continue to use the root. Active diagnostics stop into the old profile before switching. No additional timer or inventory polling is introduced.

Validation covers returning to a prior ruleset, all supported flag combinations, same-name/different-GUID characters, save/reload, missing/secret/error APIs, preservation of unstamped legacy records, shared preferences, captured references and runtime cache invalidation. Live testing of ruleset transitions remains pending.
