# Gooner Cases

A Counter-Strike inspired case-opening game for Roblox. Players earn credits, buy
cases, and watch the iconic horizontal reel spin to reveal weapon skins of
varying rarities.

## Project layout

This is a [Rojo](https://rojo.space) project.

```
default.project.json   - Rojo project definition
src/
  shared/    - ModuleScripts mirrored into ReplicatedStorage.Shared
  server/    - Scripts mirrored into ServerScriptService.Server
  client/    - LocalScripts mirrored into StarterPlayer.StarterPlayerScripts.Client
```

## Building

1. Install Rojo (`aftman add rojo-rbx/rojo` or `cargo install rojo`).
2. From this directory run `rojo build -o GoonerCases.rbxlx` to produce a place
   file, or `rojo serve` to live-sync into Roblox Studio.

## Gameplay

- New players start with a `STARTING_CREDITS` balance defined in
  `src/shared/Config.lua`.
- The lobby UI shows available cases. Buying a case immediately deducts credits
  and starts the spin animation.
- The reel scrolls horizontally and lands on a weighted-random item picked on
  the server. Server is authoritative; the client only animates.
- Unwrapped skins go into the player inventory, which persists via DataStore
  (with an in-memory fallback while testing in Studio with API access off).
- Skins can be sold from the inventory for a fraction of their nominal value.

## Adding content

- New rarities: edit `src/shared/Rarity.lua`.
- New skins: edit `src/shared/Items.lua`.
- New cases: edit `src/shared/Cases.lua`. A case is a price plus a list of item
  ids; the per-rarity odds come from `Rarity.lua`.
