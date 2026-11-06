# Roth Minimap architecture — 0.4.3

## Owners

- `RothMinimap.lua`: schema migration, access gates, native-mode detection, exact art restore, mask policy, lifecycle coalescing, reset, status and slash commands.
- `modules/Skin.lua`: addon-owned border, runes, fire, pulse and vignette.
- `modules/Ping.lua`: callback-event registration and fixed-text toast/chat presentation.
- `modules/Zoom.lua`: native wheel observation and one cancellable reset timer.
- `Options.lua`: one session-lifetime Blizzard Settings category.

No generic event bus is used. Each feature owns its direct native signal and cleanup.

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

## Lifecycle

```text
file load
  -> schema-6 migration
  -> module load
  -> Settings registration

PLAYER_ENTERING_WORLD / UI_SCALE_CHANGED
  -> one coalesced full apply
  -> refresh native-presentation reason
  -> mask + exact art + modules

EditMode.Exit / EditMode.SavedLayouts
  -> one coalesced addon-geometry refresh

combat-sensitive setting change
  -> mark one pending full apply
  -> immediately hide only disabled addon-owned visuals/timers
  -> apply once on PLAYER_REGEN_ENABLED
```

## Security boundary

`MINIMAP_PING` uses `RegisterEventCallback`, not raw `RegisterEvent`. Every secret payload argument is ignored at the callback boundary.

No borrowed event payload, foreign frame, callback handle, timer, animation, or texture is persisted.

## Performance boundary

- fire ticker: 1–20 FPS, visible-only;
- zoom: one cancellable timer;
- lifecycle: one zero-delay coalescing timer;
- frames/textures/animations: created once;
- no frame-tree enumeration, `OnUpdate`, generic polling, or recursive timers.

Live taint/rendering/profiler validation remains pending.
