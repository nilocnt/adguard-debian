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

The installer detects an existing `AdGuard` or `adguard` service account. If
neither exists, it creates the `adguard` system user and group with home
directory `/var/lib/adguard`. The generated service unit uses the detected
user and its primary group automatically.

The service is not started automatically before AdGuard CLI has been
configured. This avoids a restart loop on a fresh installation.

## Configuration and activation

Configure AdGuard CLI as the detected service user. For a new installation:

```bash
sudo -u adguard env \
  HOME=/var/lib/adguard \
  XDG_DATA_HOME=/var/lib/adguard/.local/share \
  /usr/bin/adguard-cli config
```

Activate a license when required:

```bash
sudo -u adguard env \
  HOME=/var/lib/adguard \
  XDG_DATA_HOME=/var/lib/adguard/.local/share \
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

The service unit uses the detected service account and its primary group and
runs:

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

## License

The installer changes and repository documentation are distributed under the
[GNU General Public License v3.0](LICENSE). AdGuard CLI and its bundled
components remain subject to their respective upstream licenses.

## Links

- [Project repository](https://github.com/nilocnt/adguard-debian)
- [AdGuard CLI releases](https://github.com/AdguardTeam/AdGuardCLI/releases)
- [Official AdGuard CLI documentation](https://adguard.com/en/adguard-cli/overview.html)
