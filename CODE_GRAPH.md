# Roth Minimap code graph — 0.4.4

```mermaid
flowchart LR
  TOC["RothMinimap.toc"] --> CORE["RothMinimap.lua"]
  CORE --> DB[("RothMinimapDB schema 7")]
  CORE --> MODE{"Native presentation?"}
  MODE -->|normal| MASK["square mask + exact art policy"]
  MODE -->|hybrid / housing| FALLBACK["default mask + restore art"]
  CORE --> SKIN["modules/Skin.lua"]
  CORE --> PING["modules/Ping.lua"]
  CORE --> ZOOM["modules/Zoom.lua"]
  CORE --> OPT["Options.lua"]
  PING --> CALLBACK["MINIMAP_PING CallbackEvent"]
  ZOOM --> WHEEL["native OnMouseWheel post-hook"]
  SKIN --> OWNED["addon-owned regions + adaptive ticker"]
  OPT --> DB
```

No edge grants ownership of `MinimapCluster`, `MinimapBackdrop`, Hybrid Minimap, MapCanvas masks, housing overlays, or third-party buttons.
