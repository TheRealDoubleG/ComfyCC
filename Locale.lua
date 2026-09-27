ComfyCC = ComfyCC or {}
local CC = ComfyCC

local locale = GetLocale and GetLocale() or "enUS"
local de = locale == "deDE"

local EN = {
    ENABLE = "Enable ComfyCC",
    ENABLED_MSG = "enabled.",
    DISABLED_MSG = "disabled.",
    SHOW_DECIMALS = "Show tenths below threshold",
    MIN_DURATION = "Minimum cooldown duration",
    DECIMAL_THRESHOLD = "Decimal threshold",
    FONT_SIZE = "Countdown font size",
    TEXT_SCALE = "Countdown scale",
    MIN_ICON_SIZE = "Minimum icon size",
    SHOW_ONLY_FINAL = "Only show during final seconds",
    FINAL_SECONDS = "Final-seconds window",
    AVOID_DUPLICATE = "Avoid duplicate countdown text",
    SAFETY_NOTE = "Protected/secret cooldown values and forbidden frames are skipped safely. Existing Blizzard or addon countdown text takes priority when duplicate protection is enabled.",
    TAB_GENERAL = "General",
    TAB_INFO = "Info",
    SETTINGS_DESC = "Open the ComfyCC configuration window.",
    SETTINGS_OPEN = "Open ComfyCC settings",
    INFO_TITLE = "ComfyCC",
    INFO_VERSION = "Version",
    INFO_BUILD_DATE = "Build date",
    INFO_STATUS = "Status",
    INFO_CLIENT = "Current client",
    INFO_TESTED_TARGET = "Tested target",
    INFO_COMPAT_STATUS = "Compatibility",
    INFO_AUTHOR = "Author",
    INFO_DISCORD = "Discord",
    INFO_GITHUB = "GitHub",
    INFO_COMMANDS = "Slash commands",
    INFO_COPY = "Click the field to copy",
    INFO_NOTICE = "ComfyCC only changes cooldown visuals. It does not automate gameplay or trigger abilities.",
    INFO_THANKS = "Thanks for using ComfyCC! Feedback and bug reports are welcome via Discord.",
    COMPAT_MATCH = "Compatible",
    COMPAT_UPDATE_REQUIRED = "Interface differs from the tested target",
}

local DE = {
    ENABLE = "ComfyCC aktivieren",
    ENABLED_MSG = "aktiviert.",
    DISABLED_MSG = "deaktiviert.",
    SHOW_DECIMALS = "Zehntelsekunden unter Grenzwert anzeigen",
    MIN_DURATION = "Mindestdauer für Cooldown-Zahl",
    DECIMAL_THRESHOLD = "Grenzwert für Dezimalanzeige",
    FONT_SIZE = "Schriftgröße der Cooldown-Zahl",
    TEXT_SCALE = "Skalierung der Cooldown-Zahl",
    MIN_ICON_SIZE = "Mindestgröße des Icons",
    SHOW_ONLY_FINAL = "Nur in den letzten Sekunden anzeigen",
    FINAL_SECONDS = "Zeitfenster der letzten Sekunden",
    AVOID_DUPLICATE = "Doppelte Cooldown-Zahlen vermeiden",
    SAFETY_NOTE = "Geschützte/Secret-Cooldownwerte und verbotene Frames werden sicher übersprungen. Bereits vorhandene Blizzard- oder Addon-Zahlen haben bei aktiviertem Duplikatschutz Vorrang.",
    TAB_GENERAL = "Allgemein",
    TAB_INFO = "Info",
    SETTINGS_DESC = "Öffnet das ComfyCC-Einstellungsfenster.",
    SETTINGS_OPEN = "ComfyCC-Einstellungen öffnen",
    INFO_TITLE = "ComfyCC",
    INFO_VERSION = "Version",
    INFO_BUILD_DATE = "Build-Datum",
    INFO_STATUS = "Status",
    INFO_CLIENT = "Aktueller Client",
    INFO_TESTED_TARGET = "Getestetes Ziel",
    INFO_COMPAT_STATUS = "Kompatibilität",
    INFO_AUTHOR = "Autor",
    INFO_DISCORD = "Discord",
    INFO_GITHUB = "GitHub",
    INFO_COMMANDS = "Slash-Befehle",
    INFO_COPY = "Feld anklicken zum Kopieren",
    INFO_NOTICE = "ComfyCC verändert ausschließlich die Cooldown-Darstellung. Es automatisiert keine Spielaktionen und löst keine Fähigkeiten aus.",
    INFO_THANKS = "Danke, dass du ComfyCC nutzt! Feedback und Fehlermeldungen sind über Discord willkommen.",
    COMPAT_MATCH = "Kompatibel",
    COMPAT_UPDATE_REQUIRED = "Interface weicht vom getesteten Ziel ab",
}

local STRINGS = de and DE or EN

function CC:T(key)
    return STRINGS[key] or EN[key] or key
end
