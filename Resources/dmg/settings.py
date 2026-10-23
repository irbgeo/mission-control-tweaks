# dmgbuild settings. Run via `make dmg`; "pkg" comes from -D pkg=<path to the installer>.
# The DMG holds only the installer (no .app), so macOS 27 does not show its own "Install this app?" dialog.
# Positions must match scripts/make-dmg-background.swift.
import os.path

pkg = defines.get("pkg", "build/Install MCTweaks.pkg")  # noqa: F821 (defines is injected by dmgbuild)
pkg_name = os.path.basename(pkg)

format = "UDZO"
filesystem = "APFS"
files = [pkg]
icon = "Resources/AppIcon.icns"

# dmgbuild finds background@2x.png next to it and builds a Retina image.
background = "Resources/dmg/background.png"
# Taller than the 400 pt background: macOS 27 Finder always adds a toolbar and status bar (~140 pt).
window_rect = ((200, 120), (640, 540))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 112
text_size = 13
icon_locations = {
    pkg_name: (320, 210),
}
