# RothMinimap Animation Notes

## Does WoW support GIF?
No. The UI texture system loads static texture formats (commonly **BLP** and **TGA**). If you want “GIF-like” animation, you implement it yourself.

Common approaches:

1) **Sprite sheet + changing texcoords**
   - Pack frames into a single grid texture.
   - Use `AnimateTexCoords` (Blizzard helper) or your own `SetTexCoord` stepping.

2) **Frame switching**
   - Keep a list of texture files and `SetTexture()` to the next one.
   - Simple, but more filesystem lookups and can be heavier than sprite sheets.

3) **AnimationGroup (Alpha/Scale/Rotation/Translation)**
   - Best for “breathing”, fading, pulsing, flares.
   - Does not swap pixels; it animates region properties.

## How RothMinimap animates Diablo Fire
We combine two layers:

- **Main fire layer**: frame-switch animation (a small set of fire textures) + combat/out-of-combat fades.
- **Breath layer**: separate fire overlay running a looping `AnimationGroup` alpha cycle (“smolder breathing”).

Reactions (combat / loot / achievement) use a short-lived **FX flash layer** (additive) that is event-driven.
