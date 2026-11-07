# Roth Minimap architecture — 0.4.5

## Owners

- `RothMinimap.lua`: schema migration, access gates, dynamic media root, native-mode detection, exact art restore, mask policy, lifecycle coalescing, reset, status, and slash commands.
- `modules/Skin.lua`: addon-owned border, runes, fire, pulse, and vignette.
- `modules/Ping.lua`: callback-event registration and fixed-text toast/chat presentation.
- `modules/Zoom.lua`: native wheel observation and one cancellable reset timer.
- `Options.lua`: one session-lifetime Blizzard Settings category.

No generic event bus is used. Each feature owns its direct native signal and cleanup.

## Ownership graph

```text
Blizzard / Edit Mode
  -> MinimapCluster geometry and settings
  -> native Minimap input and wheel zoom step
  -> native widgets, Hybrid Minimap, housing overlays
  -> third-party minimap buttons

Roth Minimap core
  -> schema-7 ordinary preferences
  -> media root derived from ADDON_NAME
  -> deterministic Minimap mask selection
  -> exact decorative-alpha snapshots
  -> one coalesced lifecycle refresh

feature modules
  -> addon-created noninteractive presentation
  -> bounded owned timer/ticker
```

## Presentation state

```text
normal native minimap
  -> optional square mask
  -> exact decorative art hidden
  -> addon skin visible

Hybrid Minimap or indoor housing
  -> known native default mask
  -> exact decorative art restored
  -> addon skin hidden
  -> foreign MapCanvas/masks/overlays untouched
```

## Alpha state machine

```text
ordinary visible alpha
  -> snapshot
  -> addon applies alpha 0

restore requested
  -> inaccessible alpha read: retain snapshot and fail closed
  -> current alpha is still 0: restore exact snapshot
  -> another owner changed alpha: preserve its value
  -> clear snapshot only after a resolved restore decision
```

## Lifecycle

```text
file load
  -> schema-7 migration
  -> module load
  -> Settings registration

PLAYER_ENTERING_WORLD / UI_SCALE_CHANGED
  -> one coalesced full apply
  -> refresh native-presentation reason
  -> mask + exact art + modules

EditMode.Exit / EditMode.SavedLayouts
  -> one coalesced addon-geometry refresh

explicit full apply
  -> cancel queued refresh
  -> outside combat: apply once
  -> in combat: keep one pending full apply and hide disabled owned work

PLAYER_REGEN_ENABLED
  -> drain latest pending state once
```

## Security boundary

`MINIMAP_PING` uses `RegisterEventCallback`, not raw `RegisterEvent`. Every secret payload argument is ignored at the callback boundary.

Module results must be accessible booleans or `nil`. Error reporting accepts only accessible ordinary strings and never formats an inaccessible value.

No borrowed event payload, foreign frame, callback handle, timer, animation, or texture is persisted.

## Performance boundary

- fire ticker: idle 1–8 FPS / combat 1–20 FPS, visible-only and restarted only when the selected interval changes;
- zoom: one cancellable timer;
- lifecycle: one zero-delay coalescing timer;
- frames/textures/animations: created once;
- no frame-tree enumeration, `OnUpdate`, generic polling, or recursive timers.

## Verification boundary

`tests/test_syntax.lua` compiles every Lua file individually. `tests/test_media.py` checks the shipped TGA headers, dimensions, alpha, mask shape, and fire-atlas frame structure. Static and offline runtime tests cover ownership and modeled lifecycle behavior. GitHub Actions executes all gates on `main` and pull requests.

Live taint, rendering, native callback ordering, SavedVariables serialization, and profiler measurements remain `NOT-RUN` until recorded on a named client build.
