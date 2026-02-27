# Repository Guidelines

## Project Structure & Module Organization
- Each spell lives in its own `dvr_<spell>` subfolder (e.g., `dvr_prothea/`) under this resource root. Every module follows the `client/`, `server/`, `config.lua`, `fxmanifest.lua` pattern so FiveM can `ensure dvr_<spell>`. `client/main.lua` drives visuals and effects, while `server/main.lua` enforces gameplay state and networking.
- Shared helpers, spell progression, and admin utilities are in `[escrow]/pzfx`. Update `cfg_spellbook.lua` and `cfg_spelllevel.lua` there when adding or tuning abilities; keep canonical spell IDs in `spells.txt` untouched.
- Align `fxmanifest.lua` metadata with the enclosing folder name so the runtime loads modules predictably.

## Build, Test, and Development Commands
- `refresh` reloads the resource list inside the FiveM console after renaming or adding a spell.
- `ensure dvr_<spell>` (e.g., `ensure dvr_prothea`) boots the individual resource for live testing without restarting the entire server.
- `stop dvr_<spell>` gracefully unloads a spell before redeployment or memory leak checks.
- Use `lspell <playerId> <spellId>` and `uspell <playerId> <spellId>` from the PZFX admin toolkit to grant or revoke abilities during QA sessions.

## Coding Style & Naming Conventions
- Target Lua 5.4 syntax (`lua54 'yes'` in every manifest). Four-space indentation, grouped `local` caches for natives at the top of each script, and minimal globals keep performance predictable.
- Function names modeling gameplay actions use UpperCamelCase (e.g., `CreateProtheaBarrier`); locals and helpers follow lowerCamelCase. Configuration tables prefer snake_case keys.
- Reuse shared helpers from `lib/` when available and comment succinctly on non-trivial mechanics or side effects.

## Testing Guidelines
- There are no automated suites; manual validation on staging is required. Verify particle cleanup, entity removal, and cooldown handling with instrumentation disabled (`AddExplosion`, `SetEntity*` hooks off) before merging.
- Confirm spell behavior through live tests, using `ensure dvr_<spell>` and the admin `lspell`/`uspell` helpers to trigger scenarios.
- Capture short console logs or clips showing the change, especially for visual tweaks, to accompany QA reports.

## Commit & Pull Request Guidelines
- Follow the existing terse style but lean toward imperative subjects prefixed with the resource name (e.g., `prothea: tidy orb handling`). Keep subjects under ~70 characters and add focused bodies when context is needed.
- In PR descriptions, list QA steps taken, reference relevant spell IDs or tickets, and attach media for visual changes. Note any updates to `config.lua`, `cfg_spellbook.lua`, or `spells.txt` so staging/ops can sync configs.
