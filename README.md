# ComfyCC

**Version 0.4 – Beta**  
**Tested target: WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Author: **TheRealDoubleG**  
Discord: **the.real.double.g**

ComfyCC is a lightweight cooldown-number addon for WoW Forever. It is designed to provide readable countdown numbers on Blizzard cooldown frames and on ComfyBar without changing or automating gameplay.

## 0.4 Beta

- Standalone addon: ComfyBar is not required.
- Protected/secret cooldown values are detected before any arithmetic or comparisons are attempted, preventing combat-time taint errors.
- Forbidden/protected frames are skipped safely.
- Existing Blizzard or other-addon numeric countdown text can take priority to prevent duplicate numbers.
- Adaptive update intervals reduce unnecessary CPU work on long cooldowns while keeping tenths responsive near expiration.
- Configurable minimum icon size prevents unreadable countdowns on tiny cooldown frames.
- Optional "final seconds only" mode can keep long cooldowns visually quiet until their last configured seconds.

## 0.2 Beta

- Standalone addon: ComfyBar is not required.
- Hooks standard WoW cooldown updates where the client exposes them.
- Automatically recognizes ComfyBar cooldown frames at login.
- Large centered countdown numbers.
- Hours, minutes, seconds and optional tenths.
- Configurable minimum cooldown duration to avoid showing the global cooldown.
- Configurable decimal threshold, font size and text scale.
- `/comfycc` or `/cc` opens settings.
- `/cc on` and `/cc off` toggle the addon.
- Info tab uses the same Comfy addon-family style.
- Shared **Settings** tab immediately before Info with automatic character profiles, account/custom profiles, copy-from-character and common window presentation controls.
- Settings windows can be locked, faded from 10–100%, shown without the Blizzard border on a minimalist black/grey background, and use an independent background-opacity control.

ComfyCC changes only cooldown visuals. It does not trigger abilities, items or any other gameplay action.


## Comfy Suite UI standard

ComfyCC follows Comfy Suite UI standard generation 2: a 760×620 settings window, selected-state tabs, a shared Settings tab before Info, persistent/profile-aware window presentation, consistent Info layout, Comfy Suite badge, compatibility information, author/Discord/GitHub fields and matching footer styling.
