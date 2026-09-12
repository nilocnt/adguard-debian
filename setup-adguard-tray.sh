#!/bin/sh

set -eu

SERVICE='adguard-cli.service'
BIN_DIR="${HOME}/.local/bin"
ICON_DIR="${HOME}/.local/share/icons"
AUTOSTART_DIR="${HOME}/.config/autostart"
TRAY_BIN="${BIN_DIR}/adguard-cli-tray"
ACTIVE_ICON="${ICON_DIR}/adguard-active.svg"
INACTIVE_ICON="${ICON_DIR}/adguard-inactive.svg"
AUTOSTART_FILE="${AUTOSTART_DIR}/adguard-cli-tray.desktop"

error_exit() {
  printf '%s\n' "$1" >&2
  exit 1
}

if [ "$(uname -s)" != 'Linux' ]; then
  error_exit 'This setup script only supports Linux.'
fi

if [ "$(id -u)" -eq 0 ]; then
  error_exit 'Run this script as the desktop user, not as root.'
fi

if ! command -v sudo >/dev/null 2>&1; then
  error_exit 'sudo is required to install dependencies and manage the global service.'
fi

if ! command -v apt-get >/dev/null 2>&1; then
  error_exit 'This setup script requires apt-get on Debian-based systems.'
fi

printf '%s\n' 'Installing tray dependencies...'
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  python3 \
  python3-gi \
  gir1.2-ayatanaappindicator3-0.1 \
  policykit-1

if ! systemctl cat "$SERVICE" >/dev/null 2>&1; then
  error_exit "Global service '$SERVICE' was not found. Install AdGuard CLI first."
fi

mkdir -p "$BIN_DIR" "$ICON_DIR" "$AUTOSTART_DIR"

cat > "$TRAY_BIN" <<'PYTHON'
#!/usr/bin/env python3

import os
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")

from gi.repository import Gtk, GLib, AyatanaAppIndicator3


SERVICE = "adguard-cli.service"
ICON_DIR = os.path.expanduser("~/.local/share/icons")
ACTIVE_ICON = os.path.join(ICON_DIR, "adguard-active.svg")
INACTIVE_ICON = os.path.join(ICON_DIR, "adguard-inactive.svg")


def systemctl(action):
    return subprocess.run(
        ["pkexec", "systemctl", action, SERVICE],
        check=False,
    )


def service_is_active():
    result = subprocess.run(
        ["systemctl", "is-active", "--quiet", SERVICE],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


class AdGuardTray:
    def __init__(self):
        self.indicator = AyatanaAppIndicator3.Indicator.new(
            "adguard-cli",
            INACTIVE_ICON,
            AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS,
        )
        self.indicator.set_status(
            AyatanaAppIndicator3.IndicatorStatus.ACTIVE
        )

        self.menu = Gtk.Menu()
        self.status_item = Gtk.MenuItem(label="Status: checking...")
        self.status_item.set_sensitive(False)
        self.menu.append(self.status_item)
        self.menu.append(Gtk.SeparatorMenuItem())

        for label, handler in (
            ("Start", self.start_service),
            ("Stop", self.stop_service),
            ("Restart", self.restart_service),
        ):
            item = Gtk.MenuItem(label=label)
            item.connect("activate", handler)
            self.menu.append(item)

        self.menu.append(Gtk.SeparatorMenuItem())

        logs_item = Gtk.MenuItem(label="Open logs")
        logs_item.connect("activate", self.open_logs)
        self.menu.append(logs_item)

        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", self.quit)
        self.menu.append(quit_item)

        self.menu.show_all()
        self.indicator.set_menu(self.menu)
        self.update_status()
        GLib.timeout_add_seconds(5, self.update_status)

    def update_status(self):
        active = service_is_active()
        if active:
            self.indicator.set_icon_full(ACTIVE_ICON, "AdGuard active")
            self.status_item.set_label("Status: active")
        else:
            self.indicator.set_icon_full(INACTIVE_ICON, "AdGuard inactive")
            self.status_item.set_label("Status: inactive")
        return True

    def start_service(self, _item):
        systemctl("start")
        GLib.timeout_add(500, self.update_status)

    def stop_service(self, _item):
        systemctl("stop")
        GLib.timeout_add(500, self.update_status)

    def restart_service(self, _item):
        systemctl("restart")
        GLib.timeout_add(500, self.update_status)

    def open_logs(self, _item):
        subprocess.Popen(
            [
                "x-terminal-emulator",
                "-e",
                "journalctl",
                "-u",
                SERVICE,
                "-f",
            ]
        )

    def quit(self, _item):
        Gtk.main_quit()


if __name__ == "__main__":
    AdGuardTray()
    Gtk.main()
PYTHON

cat > "$ACTIVE_ICON" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32">
  <circle cx="16" cy="16" r="14" fill="#2ecc71"/>
  <path d="M16 7l7 3v5c0 5-3 8-7 10-4-2-7-5-7-10v-5z" fill="white"/>
  <path d="M12 16l3 3 6-7" fill="none" stroke="#2ecc71"
        stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
SVG

cat > "$INACTIVE_ICON" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32">
  <circle cx="16" cy="16" r="14" fill="#e74c3c"/>
  <path d="M16 7l7 3v5c0 5-3 8-7 10-4-2-7-5-7-10v-5z" fill="white"/>
  <path d="M12 12l8 8M20 12l-8 8" fill="none" stroke="#e74c3c"
        stroke-width="2" stroke-linecap="round"/>
</svg>
SVG

cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=AdGuard CLI Tray
Comment=AdGuard CLI service indicator
Exec=${TRAY_BIN}
Icon=${ACTIVE_ICON}
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF

chmod 0755 "$TRAY_BIN"
python3 -m py_compile "$TRAY_BIN"
sudo systemctl enable "$SERVICE"
sudo systemctl daemon-reload

printf '\nAdGuard tray setup completed.\n'
printf 'Tray application: %s\n' "$TRAY_BIN"
printf 'Autostart entry: %s\n' "$AUTOSTART_FILE"
printf 'Start the tray now with: %s\n' "$TRAY_BIN"
