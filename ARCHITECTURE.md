# Roth Minimap architecture

Release `0.4.2` · SavedVariables schema `6`.

## Runtime owners

`RothMinimap.lua` owns persistence, access helpers, deterministic mask policy, exact decorative alpha ownership, lifecycle coalescing, module application, reset, and slash commands.

Feature modules own their native signals directly:

- `modules/Skin.lua`: combat events, addon-owned visual regions, geometry, fire ticker, pulse cleanup;
- `modules/Ping.lua`: `MINIMAP_PING`, fixed notification, toast lifecycle;
- `modules/Zoom.lua`: post-wheel hook, world/combat/hide cancellation, one reset timer;
- `Options.lua`: session-lifetime Settings registrations and callback-suppressed refresh.

No generic event bus rebroadcasts raw Blizzard tuples.

## Load order

```text
RothMinimap.toc
  -> RothMinimap.lua
  -> modules/Skin.lua
  -> modules/Ping.lua
  -> modules/Zoom.lua
  -> Options.lua
```

`LoadSavedVariablesFirst` makes the schema migration available before the first file. Settings register only after migration.

## Ownership graph

```text
Blizzard/Edit Mode
  -> MinimapCluster position/size/settings
  -> Minimap input and zoom step
  -> native widgets and third-party buttons

Roth Minimap core
  -> schema-6 ordinary preferences
  -> Minimap mask selection
  -> exact decorative alpha snapshots
  -> coalesced addon-owned refresh

feature modules
  -> addon-created noninteractive art/toast
  -> bounded owned timer/ticker
```

## Refresh topology

```text
PLAYER_ENTERING_WORLD -> one queued full apply
UI_SCALE_CHANGED      -> one queued full revalidation/apply
EditMode.Exit         -> same geometry queue
EditMode.SavedLayouts -> same geometry queue
combat restriction    -> one pending full/geometry flag
PLAYER_REGEN_ENABLED  -> drain the latest pending state once
```

Equivalent requests share one zero-delay cancellable timer. Full apply upgrades a queued geometry-only request.

## Persistence

Schema 6 repairs current data and migrates the pre-0.4 layout. Mutable defaults are copied, types/domains are validated, retired ownership fields are removed, and root/nested table identities are preserved.

Settings callbacks are session lifetime. Reset performs one apply and broadcasts UI updates under a callback-suppression guard.

## Evidence boundary

Static and offline tests prove only the modeled code contracts. Client rendering, native lifecycle ordering, protected/taint behavior, hotfixes, and performance remain `NOT-RUN` until measured on a named client build.
