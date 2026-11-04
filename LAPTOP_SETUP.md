# HunterTools laptop setup

Clone https://github.com/shaynec777/HunterTools-Forever and use the main branch. Pull main before installing updates.

## Install from Git

Use the laptop game folders shown by Battle.net. Copy complete addon folders, including textures, into the intended client Interface/AddOns directory:

- Forever: copy HunterTools (interface 16001).
- Classic Era: copy classic-port/source/HunterToolsClassic (interface 11509).

Keep the edition folder names intact. The .toc file must be directly inside its addon folder. The legacy FeedomaticToo folder is a Forever settings-migration loader; copy it only if migrating an old FeedomaticToo installation. Fully restart WoW for a new addon or new module; /reload loads edits to existing modules.

The editions use separate saved variables. Git contains code and reference data, not your character settings. Moving settings between computers is a separate manual operation; installing source does not copy them.

## Development

Install Python and lupa for Lua 5.1 mock tests (python -m pip install lupa). Run python classic-port/validate_classic.py for Classic checks. The root test-*.lua files exercise Forever behavior. Local build ZIPs and dependency folders are ignored. Classic data provenance is in classic-port/README.md; Forever references are in PET-DATA-SOURCES.md.
