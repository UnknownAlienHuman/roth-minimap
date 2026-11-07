# Roth Minimap code graph — 0.4.6

```mermaid
flowchart LR
  TOC["RothMinimap.toc"] --> CORE["RothMinimap.lua"]
  CORE --> DB[("RothMinimapDB schema 8")]
  CORE --> MEDIA["ADDON_NAME-derived media root"]
  CORE --> MODE{"Native presentation?"}
  CORE --> MASKMODE{"Mask transition state"}
  MASKMODE -->|square| MASK["square mask"]
  MASKMODE -->|native restore| FALLBACK["selected-build default mask"]
  MASKMODE -->|unselected + unowned| NOOP["no mask write"]
  MODE -->|hybrid / housing| FALLBACK
  CORE --> ALPHA["retained decorative-alpha snapshots"]
  CORE --> QUEUE["single coalesced refresh"]
  CORE --> SKIN["modules/Skin.lua"]
  CORE --> PING["modules/Ping.lua"]
  CORE --> ZOOM["modules/Zoom.lua"]
  CORE --> OPT["Options.lua"]
  PING --> CALLBACK["MINIMAP_PING CallbackEvent"]
  ZOOM --> WHEEL["native OnMouseWheel post-hook"]
  SKIN --> OWNED["addon-owned regions + adaptive ticker"]
  OPT --> DB
  TESTS["recursive syntax + static + runtime + exact media gates"] --> CORE
  TESTS --> SKIN
  TESTS --> PING
  TESTS --> ZOOM
```

No edge grants ownership of `MinimapCluster`, `MinimapBackdrop`, Hybrid Minimap, MapCanvas masks, housing overlays, third-party buttons, or an arbitrary foreign mask.
