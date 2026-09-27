# ComfyCC Changelog

## 0.5 Beta – 27.09.2026
- Fixed Background opacity so 0% fully removes the Comfy window background while the border can remain.
- Aligned the shared Load / copy control with its profile dropdown.


## 0.4 Beta – 27.09.2026
- Added protected/secret-value guards before cooldown arithmetic or comparisons to avoid combat-time taint errors.
- Added forbidden-frame checks before registering, updating or clearing cooldown frames.
- Added conservative duplicate-countdown protection: existing numeric Blizzard/addon countdown text can take priority over ComfyCC.
- Added adaptive update intervals: fast near decimal thresholds, slower for long cooldowns to reduce CPU work.
- Added configurable minimum icon size for countdown text.
- Added optional "final seconds only" display with a configurable 5–120 second window.
- Kept protected cooldowns fail-safe: when WoW does not expose usable numeric values, ComfyCC hides its custom number instead of guessing or throwing Lua errors.


## 0.3 Beta – 27.09.2026
- Added the suite-wide **Settings** tab immediately before Info.
- Added automatic per-character, account and named custom saved profiles, including copy/load from another known character.
- Added settings-window lock, 10–100% window opacity, optional Blizzard border, minimalist black/grey background and independent background opacity.
- Changed active tabs to a selected/pushed state instead of looking disabled.
- Cleaned Info footer spacing and adopted Comfy Suite UI standard generation 2.


## 0.2 Beta – 27.09.2026
- Adopted the shared Comfy Suite UI standard.
- Resized the settings window to the common 760×620 family size.
- Standardized the Info tab with GitHub field, copyright, footer spacing and Comfy Suite badge.
- Added Comfy Suite metadata to the TOC for family identification.
- Normalized the Info-panel backdrop paths.


## 0.1 Beta – 27.09.2026

- Initial testing build.
- Added cooldown countdown text overlay.
- Added hooks for standard `CooldownFrame_Set` and `CooldownFrameMixin:SetCooldown` paths when available.
- Added ComfyBar cooldown discovery at login.
- Added configurable minimum duration, decimal display, decimal threshold, font size and scale.
- Added Blizzard-style General and Info settings tabs.
- Added `/comfycc`, `/cc`, `/cc on` and `/cc off`.
