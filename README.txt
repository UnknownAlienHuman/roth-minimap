Roth Minimap (v0.3.5) — Midnight-ready minimap addon

Core goals
- Lightweight and event-driven (no always-on OnUpdate loops).
- Safe behavior in combat (defers protected changes).
- In-game Settings UI (Retail Settings → AddOns → Roth Minimap).

Features
1) Square minimap
- Mask-based square shape.
- Cluster size/scale/position controls + Alt-drag mover.

2) Diablo skin (animated + reactive)
- Stone border + rune glow + animated fire overlay (12-frame loop).
- Reactions:
  * Combat: quick flare, then steady burn.
  * Ping: short pulse burst.
  * Damage taken: hot micro-flicker (throttled).
  * Low health: stronger red rage + faster fire.
  * Mounted/resting: subtle dim (optional).

3) Ping notification
- Toast near minimap, or chat output.
- Optional sound.
- Ping also triggers a Diablo pulse if the skin is enabled.

4) Mousewheel zoom + auto zoom-out
- Mousewheel zoom via HookScript (robust with other addons).
- Auto reset with delay (smooth or snap).



5) Minimap button bag
- Collects addon minimap buttons into a single popup tray.
- Rescan command for edge cases.

Slash commands
- /rmmap : open settings
- /rmmap unlock : enable mover (Alt-drag)
- /rmmap lock : disable mover
- /rmmap scan : rescan minimap buttons
- /rmmap reset : wipe saved variables and reload UI

Notes
- This addon is written from scratch. No code is copied from SexyMap or Leatrix.
- If something fails in combat, the addon defers the change until combat ends.
