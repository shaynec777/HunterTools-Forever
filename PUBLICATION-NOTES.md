# HunterTools publication description

## Required for the next publication

Logo direction requested October 16, 2026: replace the publication logo for the next release with an original hunter jackknife/multi-tool emblem, with a bow, gun, tallstrider and trap extended. The user approved artwork/huntertools-multitool-concept-v1.png and explicitly requested it in the main menu header. Use that design for the next publication.

Add a prominent **New in this update** section to the published description, listing the new features included in that release, with a **Bug fixes** subsection for fixes. Refresh both lists against the final release contents and testing results before publishing.

Draft for the currently unpublished changes:

### New in this update

- Optional movable pet-status window with health and focus bars, happiness, loyalty, training points, diet, food supply, feeding status, and last successful feeding.
- Mouseover status tips for your own pet, with separate Window and Mouseover checkboxes for the details you want to see.
- Saved window position, position locking, and a reset-position control.
- Private feeding confirmation: “Fed <petname> a delicious <petfood>.”

#### Bug fixes

- Saved food lists use pet name and family, with safe legacy cleanup, clearer deletion feedback, and a confirmed inactive-list cleanup option. Summoning creates or reuses a default list with existing food protections applied.

- Fix missing learned-ability updates when hunter training spell IDs differ from pet casting spell IDs, using reference mappings for 32 pet abilities and their ranks.
- Recognize Screech and Demoralizing Screech as the same ability when displaying learned status.
- Prevent premature low-food warnings while inventory is settling after login.

Published as HunterTools 3.0.2 on GitHub on October 16, 2026; submitted to CurseForge with automatic publication after approval. CurseForge file ID: 9206832. Both public release notes include New in this update and Bug fixes sections. The Android app and Windows server-status widget are separate projects and are not HunterTools release features.

Testing update, October 16, 2026: the user confirmed the food-warning fix after logging out and back in, with no false warning immediately or after inventory settled.

FeedomaticToo has morphed into HunterTools due to the many great suggestions we've received!

## Pet database caveat

Pet ability and diet information currently uses a Classic baseline while Forever is in beta and may differ from Forever. Live Beast Lore information takes priority. We plan to verify and refine the database after Forever leaves beta.

## Feedback request

If a feature doesn't work, please leave a comment describing what happened, which feature you were using, and any error message so we can investigate.

## Closing line for the longer mod description

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!

Testing update, October 16, 2026: user confirmed pet-status window appearance, independent display checkboxes, and pet details appearing only on their own pet. User also confirmed the feeding chat message in-game.

First logo concept saved: artwork/huntertools-multitool-concept-v1.png. User approved this design.

Testing update, October 16, 2026: the user confirmed the redesigned menus look good. Ranged weapon comparisons and scope previews are the next local test feature. The approved jackknife logo now replaces the Hunter class icon in the main menu header.

Next publication description must include the character Auto Shot DPS formula, the distinction from base weapon DPS, and the documented calculation limits. See DESCRIPTION.md and WEAPON-COMPARISONS.md. The user screenshot confirmed one equipped-weapon damage range against the character sheet (17.9-24.9 vs displayed 17-25); candidate swap/scopes remain to be verified in game.

Label ranged weapon comparisons and scope previews **Experimental** in the next publication description. The settings title and comparison tooltip also carry that label.

## HunterTools 3.1.0 publication — October 16, 2026

Published GitHub release v3.1.0: https://github.com/shaynec777/HunterTools/releases/tag/v3.1.0 (commit 4d7087fd5a03e5fbbc3bb976092a624e7d912d68). The release includes the approved jackknife logo and explicitly labels ranged weapon comparisons and scope previews Experimental, with the character Auto Shot DPS formula and calculation limits.

CurseForge logo, summary, and description were saved and verified publicly. Corrected file 9217350 is Under Review with automatic publication after approval. The initial file 9217314 was rejected for top-level documentation; the replacement ZIP contains only addon folders. GitHub's ZIP asset was also replaced with the corrected package. SHA256: 43f7fa20afec91e2685fb60e9e34114df257e9ea63c8565a8f029e2ee985a523. Lua 5.1 syntax, feature regression checks, TOC references, ZIP integrity, and release labels passed before publication.

CurseForge approval verified October 16, 2026: corrected HunterTools 3.1.0 file 9217350 is Approved. https://www.curseforge.com/wow/addons/huntertools/files/9217350


## HunterTools 3.1.1 — October 17, 2026

Published on GitHub: https://github.com/shaynec777/HunterTools/releases/tag/v3.1.1 . Commit 6ddd37453fb1c6076ddcc72598107d3eb48fd2a9. ZIP SHA256 a240183ada1fc00aaf9732794ab6ba1e54a27c83637146dcf523c17fd6b3d4f8 (261331 bytes).

CurseForge file 9233149 submitted with automatic publication; Under Review at last check. Public feature description saved successfully. Hunger/inventory/new-pet sound fixes, clearer selected tabs, Petopia Forever/community beast facts, local collection/export and source fallbacks included. Community and Classic-linked provenance retained; ranged weapon comparisons and scope previews remain Experimental, with formula and limits. Automated release checks passed. User confirmed hungry banner delivery after the latest food-scan fix. Collection still needs broader in-game validation. Installed version synchronized to 3.1.1 with backup and hash verification.

Testing update, October 17, 2026: user confirmed that after the hunter learns a pet ability from a newly tamed pet, mouseover information for a beast teaching that ability/rank shows Learned. This confirms the automatic learned-rank mouseover update; it does not independently confirm the ability browser's next-rank transition.

Testing update, October 17, 2026: user confirmed the aspect button works and the pet healing-distance warning works with the larger text. This confirms the reported button behavior and warning presentation; combat aspect switching, intentional-cancellation handling and the instance Pack replacement chooser were not separately confirmed.

Ongoing requirement, October 17, 2026: always show the current addon version in the main menu. The label now reads F.VERSION dynamically when the menu refreshes; maintain this in all future releases.

## HunterTools 3.1.2 � October 18, 2026

Published GitHub release https://github.com/shaynec777/HunterTools/releases/tag/v3.1.2 at commit 80632854f8db5b5b78f51c45fc37abd39b7c7d33. ZIP SHA256 db1975c7185212eb1332a2a65aa60050c8f993f55ec5c0e447a966ed5c542079 (271730 bytes), uploaded GitHub asset digest verified. CurseForge file 9239112 is Under Review with automatic publication enabled. Public project description saved successfully. Aspect controls, Mend Pet range warning, native restricted-health visual/death alerts and menu version included. Sound/chat restriction explicitly documented; weapon comparisons/scopes remain Experimental with formula retained. All release regressions, Lua 5.1 syntax/TOC and addon-only ZIP root checks passed. Installed both addon folders with backup and complete source hash verification.

## HunterTools Forever 3.1.6 — November 4, 2026

GitHub main and tag v3.1.6 published at 601a1a6. Release: https://github.com/shaynec777/HunterTools-Forever/releases/tag/v3.1.6

Addon-only ZIP SHA256: 506156bfba45dc0157f03eb8f654d1ed7df9b003d5060b6410798865f199011a. Forever Lua regression files passed when run with their intended fixtures; syntax, TOC references, ZIP bytes and uploaded GitHub asset digest verified. User reports installed build functional. CurseForge submission remains pending author upload-token configuration; no CurseForge upload has been made for this version yet.

CurseForge upload accepted November 4, 2026 via the author upload API. Project 1740323; file 9446546; display name HunterTools Forever 3.1.6; release type release; API-resolved Forever 1.60.1; automatic publication after approval enabled. URL: https://www.curseforge.com/wow/addons/huntertools/files/9446546 . Uploaded ZIP SHA256 remains 506156bfba45dc0157f03eb8f654d1ed7df9b003d5060b6410798865f199011a. API acceptance confirms submission, not moderation approval. Token is encrypted locally in an ignored folder and is not included in Git.

## Feeder text releases — November 6, 2026

Prepared Forever 3.1.7 and Classic 0.1.0-beta2. User confirmed the Forever feeder controls and blank unavailable-happiness label in game. Both editions passed feeder-mode regressions and Lua 5.1 syntax. Forever focused menu, food-login, range and Mend Pet suites passed. Classic validation passed 25 suites; the shared combat-range assertion fails against the older Classic range implementation and is outside this feeder change. Classic feeder in-game validation remains pending. Packages contain only their respective addon folders and were verified byte-for-byte.

Published November 6, 2026 at commit 9a99795:
- Forever GitHub release: https://github.com/shaynec777/HunterTools-Forever/releases/tag/v3.1.7 . ZIP SHA256 e589ea1fb1efd6f14fe128ba6b571d5befd9b1510c0b64dd36594ef87232b29e. CurseForge project 1740323 accepted file 9472123 for Forever 1.60.1, release channel, automatic publication after approval.
- Classic GitHub release: https://github.com/shaynec777/HunterTools-Forever/releases/tag/classic-v0.1.0-beta2 . ZIP SHA256 b3535441cf965a668338128bb4bb476727895cf6af7da982c2a493a4db189c40. CurseForge project 1760155 accepted file 9472125 for Classic Era 1.15.9, beta channel, automatic publication after approval. Includes the previously prepared NPC tameability module; full restart required.
GitHub uploaded asset digests verified. CurseForge acceptance confirms submission, not moderation approval.

## Website description synchronization — November 6, 2026

Verified public file listings via CFWidget: Forever 3.1.7 (9472123), Classic 0.1.0-beta2 (9472125). Updated both local DESCRIPTION.md sources with explicit matching versions and feeder controls. CurseForge author-token POST /api/projects/{projectId}/update-project accepted both descriptions and returned their correct project IDs (1740323 and 1760155). Public feed readback still served stale descriptions immediately afterward; visible propagation remains unverified. Future releases must synchronize the main website description with the approved downloadable version, separately from file changelogs.

## Shared HunterTools version sequence — November 6, 2026

Classic is now numbered 3.1.7 to match Forever. GitHub classic-v3.1.7 published at 37592e0; verified ZIP SHA256 9ed43d2fa481f76a20966217b36d262c1715d2991405a8eb3dbe3472764bb9c8. CurseForge accepted Classic file 9472375 on the beta channel. Public download still showed beta2 at last check, so public description remains beta2 until approval. Future editions follow the shared Forever version sequence with separate packages and settings.

## Tracking icon priority release 3.1.8

Published GitHub v3.1.8 and classic-v3.1.8 at c298d37. Forever ZIP SHA256 09ef93bb3fd852ca93179e61ed0a72d56c2c0bedafa7ec4ab0b5bc45e80baed2; Classic cb88265b239668c411a4f0635ce1d1f862ea9cf574b19bc83f71e684b7dcce1f. GitHub asset digests, Lua 5.1 syntax, tracking regressions and ZIP/source equality verified. User confirmed Forever icon preference in game. CurseForge accepted Forever file 9480379 and Classic file 9480380 for automatic publication after approval. Public downloads still 3.1.7 for both at last check; descriptions remain aligned to approved 3.1.7. Classic retains beta status.

## Performance release 3.1.9

Ported the combined performance changes to Classic. User played the Forever preview without observing issues; original reported stutter resolution is unconfirmed. Both editions pass Lua 5.1 syntax and targeted event/cache regressions. Thirteen focused Forever suites passed; Classic validation passed 25 suites with the pre-existing shared combat-range assertion still failing. Package roots, TOC references, ZIP CRC and source/archive equality checked. Forever SHA256 fcf8c809418577802f01640e1ce6c4cccb1d71c9d2217d7b729404c832318e85; Classic ca1eb202d24515711562a42dc7025dfa34560ca9a184b402f9a2363e07e01520. Source and installed Forever backups preserved under pre-performance-20261109-030722.

GitHub releases v3.1.9 and classic-v3.1.9 published at 1199cf5; uploaded asset digests verified. CurseForge accepted Forever file 9520962 and Classic file 9520963 with automatic publication after approval. Both public downloads currently show 3.1.8, so both website descriptions were synchronized via author API to the 3.1.8 description sources. Advance descriptions to 3.1.9 after approval. Classic retains beta status.

## 3.1.10 — November 9, 2026

Published GitHub v3.1.10 and classic-v3.1.10 at 9b60ba7. Both editions include the missing-item-ID loading-loop fix, cached quest food names, reduced disabled/idle work and pet-status text cleanup. Temporary diagnostics excluded. Forever SHA256 b089192ee47dd7ae8efa405bd2ce5c0828b3851486017d94d771ed8569fff218; Classic 515599b1bdfeb426cdf3784c7b77c2bba4b4836ba11be99cceacc303ccf6a781. GitHub asset digests verified. Targeted regressions pass for both; Classic broader validation retains the pre-existing range assertion failure. User observed inventory scan rate drop from 5.31/s to 0.15/s in Forever; Classic live confirmation pending.

CurseForge accepted Forever file 9522244 and Classic file 9522245 with automatic publication after approval; Classic remains beta. Both public downloads are 3.1.9 at last check. Author API accepted live descriptions matching 3.1.9 with linked thanks to AalSupes and BluBuryPi. Both 3.1.10 description sources and release notes include the same credits. Advance website version text after approval.

## 3.1.11 — November 9, 2026

Published GitHub v3.1.11 and classic-v3.1.11 at a4ee29b. Both editions include sidebar settings navigation, direct per-line tooltip settings, green buttons, softer rounded tooltip-style borders and 80% opaque shared backgrounds. Credits to AalSupes and BluBuryPi retained. Verified Lua 5.1 syntax, targeted navigation/tooltip/styling checks, package contents and uploaded GitHub asset digests. Forever ZIP SHA256 e582742eb79fd76806c4b4a506ff1f64420ef446f8c1c4a2bf23e346c3b73033; Classic c32754d69a4a168831a8c25148d61baec6c339a762353385c8fb6b264c8de258. Classic broader validation: 25 passed, existing range assertion failure unchanged; Classic live confirmation pending.

CurseForge accepted Forever file 9522426 and Classic file 9522427 with automatic publication after approval. Website descriptions synchronized by author API to the public feed's current 3.1.9 downloads at last check; feed may lag approvals. Advance descriptions to 3.1.11 once publicly downloadable. Classic retains beta status.

## Release policy — effective November 9, 2026

User instruction: update CurseForge website notes to the latest version uploaded for approval immediately, even before that version is available for download. This supersedes the prior approved-download-only description policy. Do not claim moderation approval until verified. Corrective suffixes such as Classic 3.1.11a may differ from the unchanged Forever release.
