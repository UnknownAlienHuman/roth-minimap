# Roth Minimap code graph — 0.4.5

```mermaid
flowchart LR
  TOC["RothMinimap.toc"] --> CORE["RothMinimap.lua"]
  CORE --> DB[("RothMinimapDB schema 7")]
  CORE --> MEDIA["ADDON_NAME-derived media root"]
  CORE --> MODE{"Native presentation?"}
  MODE -->|normal| MASK["square mask + exact art policy"]
  MODE -->|hybrid / housing| FALLBACK["default mask + restore art"]
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
  TESTS["syntax + static + runtime + media gates"] --> CORE
  TESTS --> SKIN
  TESTS --> PING
  TESTS --> ZOOM
```

No edge grants ownership of `MinimapCluster`, `MinimapBackdrop`, Hybrid Minimap, MapCanvas masks, housing overlays, or third-party buttons.
