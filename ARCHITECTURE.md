# Roth Minimap architecture

`RothMinimap.lua` owns namespace, defaults/migrations, SavedVariables, minimap geometry and common safe helpers. Feature modules are separated by concern: `modules/Skin.lua` renders the Diablo layers, `modules/Ping.lua` handles notifications, `modules/Zoom.lua` controls wheel/auto zoom, `modules/ButtonBag.lua` discovers and restores addon buttons, and `modules/AddonCompartment.lua` exposes the launcher. `Options.lua` builds the Blizzard Settings page.

Combat-sensitive button reparenting is deferred and restored through ButtonBag state. The active TODO specifically requires runtime proof that protected/forbidden buttons are not moved in combat and that only one bag window exists.
