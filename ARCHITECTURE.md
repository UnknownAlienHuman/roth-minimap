# Roth Minimap architecture — 0.4.6

## Owners

- `RothMinimap.lua`: schema migration, access gates, dynamic media root, transition-owned mask policy, native-mode detection, exact art restore, lifecycle coalescing, reset, status, and slash commands.
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
  -> schema-8 ordinary preferences
  -> media root derived from ADDON_NAME
  -> transition-scoped Minimap mask writes
  -> exact decorative-alpha snapshots
  -> one coalesced lifecycle refresh

feature modules
  -> addon-created noninteractive presentation
  -> bounded owned timer/ticker
```

## Mask state machine

```text
no Roth mask write
  + square feature disabled
  -> no-op; preserve existing foreign mask

normal + square selected
  -> SetMaskTexture(square)
  -> mode = square

square mode leaves / addon disables
  -> SetMaskTexture(selected-build native default)
  -> mode = none

Hybrid/housing + square selected
  -> SetMaskTexture(selected-build native default)
  -> mode = native

PLAYER_ENTERING_WORLD
  -> mark current mode for one revalidation
```

The public Minimap API has no selected exact getter contract, so arbitrary foreign-mask restoration is not claimed.

## Presentation state

```text
normal native minimap
  -> optional square mask
  -> exact decorative art hidden
  -> addon skin visible

Hybrid Minimap or indoor housing
  -> known native default when Roth square mode is selected
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
  -> schema-8 migration
  -> module load
  -> Settings registration

PLAYER_ENTERING_WORLD
  -> invalidate mask mode
  -> one coalesced full apply

UI_SCALE_CHANGED
  -> one coalesced full apply

EditMode.Exit / EditMode.SavedLayouts
  -> one coalesced addon-geometry refresh

explicit full apply
  -> cancel queued refresh
  -> outside combat: apply once
  -> in combat: keep one pending full apply and hide disabled owned work
  -> lifecycle bursts in combat: update pending flags without creating timers

PLAYER_REGEN_ENABLED
  -> drain latest pending state once
```

## Persistence

Schema 8 preserves Settings-bound root/nested table identity. Legacy border/rune alpha `0` becomes a disabled layer with a usable positive color alpha; enabling the current checkbox therefore produces visible output.

## Security boundary

`MINIMAP_PING` uses `RegisterEventCallback`, not raw `RegisterEvent`. Every secret payload argument is ignored at the callback boundary.

Module results must be accessible booleans or `nil`. Error reporting accepts only accessible ordinary strings and never formats an inaccessible value.

No borrowed event payload, foreign frame, callback handle, timer, animation, or texture is persisted.

## Performance boundary

- fire ticker: idle 1–8 FPS / combat 1–20 FPS, visible-only;
- zoom: one cancellable timer, rescheduled only when its configured delay changes;
- lifecycle: one zero-delay coalescing timer;
- frames/textures/animations: created once;
- mask writes: only transitions plus world-entry revalidation;
- no frame-tree enumeration, `OnUpdate`, generic polling, or recursive timers.

## Verification boundary

`tests/test_syntax.lua` discovers every Lua file recursively. `tests/test_media.py` checks the exact TGA manifest, headers, dimensions, alpha, mask shape, and every atlas frame. Static and offline runtime tests cover ownership and modeled lifecycle behavior. GitHub Actions executes all gates with a pinned action and read-only token.

Live taint, rendering, native callback ordering, SavedVariables serialization, and profiler measurements remain `NOT-RUN` until recorded on a named client build.
