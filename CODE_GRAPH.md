# Roth Minimap code graph

```mermaid
flowchart LR
  T["RothMinimap.toc / Interface 120105"] --> SV["LoadSavedVariablesFirst"]
  SV --> C["RothMinimap.lua"]
  T --> S["modules/Skin.lua"]
  T --> P["modules/Ping.lua"]
  T --> Z["modules/Zoom.lua"]
  T --> O["Options.lua"]

  C --> DB[("RothMinimapDB v5; stable table identity")]
  O --> SET["Blizzard Settings"]
  SET --> DB
  C --> MASK["Minimap mask"]
  C --> ART["MinimapCompassTexture + BorderTop alpha"]

  E["Blizzard Edit Mode"] --> M["Minimap / MinimapCluster geometry"]
  M --> S
  S --> OWN["addon-owned border/runes/fire/pulse/vignette"]
  P --> OWN

  W["Blizzard MinimapMixin:OnMouseWheel"] --> STEP["one native zoom step"]
  STEP --> Z
  Z --> RESET["one cancellable reset timer"]

  TS["tests/test_contracts_12_1_5.lua"] --> C
  TR["tests/test_runtime_stubs.lua"] --> DB
  TR --> ART
  TR --> RESET
```

Clock, calendar, tracking, difficulty, mail, housing/landing-page controls, queues, Addon Compartment, and native/third-party minimap buttons have no ownership edge from Roth Minimap.
