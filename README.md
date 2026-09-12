# AdGuard CLI Installer for Debian-based Linux

This repository provides a small installer based on the official AdGuard CLI
installation script. It downloads the release archive from the official
AdGuard CLI GitHub repository, installs the program under
`/usr/lib/adguard-cli`, and creates a systemd service.

This is an unofficial installation wrapper. It is not an official AdGuard
package or installer.

## Requirements

- Debian or another systemd-based Linux distribution.
- `amd64` or `aarch64` architecture.
- `curl`, `tar`, and `sudo` when the script is not run as root.
- Root access.

## Installation

Download the installer and run:

```bash
chmod +x install.sh
sudo ./install.sh
```

The installer downloads the official release archive and installs the files
under:

```text
/usr/lib/adguard-cli/
```

It also creates:

```text
/usr/bin/adguard-cli -> /usr/lib/adguard-cli/adguard-cli
/usr/lib/adguard-cli/adguard-cli.service
/etc/systemd/system/adguard-cli.service -> /usr/lib/adguard-cli/adguard-cli.service
```

The installer does not create or modify a service user or group. It identifies
the current user running the installer (or `SUDO_USER` when invoked with
`sudo`) and replaces the `SERVICE_USER` and `SERVICE_GROUP` placeholders in
the generated service unit with that user's name and primary group.

The service is not started automatically before AdGuard CLI has been
configured. This avoids a restart loop on a fresh installation.

## Configuration and activation

Configure AdGuard CLI as the user that will run the service:

```bash
sudo env \
  HOME="$HOME" \
  XDG_DATA_HOME="$HOME/.local/share" \
  /usr/bin/adguard-cli config
```

Activate a license when required:

```bash
sudo env \
  HOME="$HOME" \
  XDG_DATA_HOME="$HOME/.local/share" \
  /usr/bin/adguard-cli activate YOUR-ACTIVATION-CODE
```

Then enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now adguard-cli.service
```

Check its status and logs:

```bash
systemctl status adguard-cli.service
sudo journalctl -u adguard-cli.service -f
```

## Service

The installed unit is intentionally kept at:

```text
/usr/lib/adguard-cli/adguard-cli.service
```

The system-wide link is:

```text
/etc/systemd/system/adguard-cli.service
```

The service unit uses the installer user's account and primary group and runs:

```text
/usr/bin/adguard-cli start
```

## Options

The installer retains the official script options:

```text
Usage: install.sh [-o output_dir] [-v] [-h] [-u] [-V version] [-l]
```

Examples:

```bash
sudo ./install.sh -v
sudo ./install.sh -V 1.4.13
sudo ./install.sh -u
```

By default, the current script version is used. The `-l` option is intended
for installing a local archive with the same naming expected by the official
script.

## Removal

Stop and remove the installed service and program with:

```bash
sudo ./install.sh -u
```

The service link, service file, `/usr/bin/adguard-cli` link, and installed
program files are removed. The service account and its data are preserved so
that an accidental reinstall does not delete configuration.

## Tray indicator

For a visual status indicator for the global systemd service, run the setup
script as the desktop user:

```bash
./setup-adguard-tray.sh
```

The script installs the required packages, creates green and red status icons,
installs the tray application under `~/.local/bin/`, and enables automatic
startup with the graphical session. The tray application controls the global
`adguard-cli.service` through PolicyKit and checks its status every five
seconds.

Start it immediately with:

```bash
~/.local/bin/adguard-cli-tray
```

Run the setup script as the regular desktop user, not with `sudo`.

## License

The installer changes and repository documentation are distributed under the
[GNU General Public License v3.0](LICENSE). AdGuard CLI and its bundled
components remain subject to their respective upstream licenses.

## Links

- [Project repository](https://github.com/nilocnt/adguard-debian)
- [AdGuard CLI releases](https://github.com/AdguardTeam/AdGuardCLI/releases)
- [Official AdGuard CLI documentation](https://adguard.com/en/adguard-cli/overview.html)
