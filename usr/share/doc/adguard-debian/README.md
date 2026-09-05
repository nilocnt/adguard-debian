# AdGuard CLI Debian Package

[![GitHub Release](https://img.shields.io/github/v/release/nilocnt/adguard-debian?style=for-the-badge)](https://github.com/nilocnt/adguard-debian/releases)
[![Package](https://img.shields.io/badge/package-.deb-orange?style=for-the-badge&logo=debian)](https://github.com/nilocnt/adguard-debian/releases/latest)
[![Architecture](https://img.shields.io/badge/architecture-amd64-green?style=for-the-badge)](https://github.com/nilocnt/adguard-debian/releases/latest)
[![License](https://img.shields.io/badge/license-GLP--3.0-blue?style=for-the-badge)](LICENSE)

An unofficial Debian package for [AdGuard CLI](https://adguard.com/en/adguard-cli/overview.html), configured to run as a system-wide systemd service.

The package is intended for Debian-based systems running on `amd64` architecture.

For official AdGuard for Linux product information and installation instructions, see the [AdGuard for Linux overview](https://adguard.com/en/adguard-linux/overview.html?source=ag_products_page). This repository provides an alternative Debian package-based installation and is not the official AdGuard installer.

## Overview

AdGuard CLI provides system-wide ad and tracker blocking through a command-line interface. This package integrates the CLI with systemd and runs it under a dedicated service account instead of a human user's home directory.

AdGuard CLI supports a trial period before a license key or serial number is required.

## Features

- System-wide AdGuard CLI service integration.
- Automatic startup through systemd.
- Dedicated `adguard` system user and group.
- Persistent service data in `/var/lib/adguard-cli`.
- Explicit `AG_CLI_DATA_PATH` configuration.
- Automatic migration from supported legacy installation paths.
- Foreground execution under systemd with automatic restart.

## Requirements

- Debian or a Debian-based distribution.
- `systemd`.
- `amd64` architecture.
- Root or `sudo` access.

The package depends on `adduser` to create the dedicated `adguard` system user and group.

## Installation

Download the latest package from the [GitHub Releases page](https://github.com/nilocnt/adguard-debian/releases/latest), then install it with:

```bash
sudo apt install ./adguard-debian_VERSION_amd64.deb
```

During installation, the package:

1. Creates the `adguard` system user and group if they do not already exist.
2. Creates `/var/lib/adguard-cli` with the appropriate ownership and permissions.
3. Migrates configuration data from supported legacy locations when necessary.
4. Reloads, enables, and starts the systemd service when systemd is available.

The service starts automatically so the AdGuard trial can be used immediately. On upgrades, an existing installation is restarted automatically.

Check the service status:

```bash
systemctl status adguard-cli.service
```

## Activation

Activation is performed separately and is not automated by the package. This prevents license keys from being stored in package metadata, repository files, or package scripts.

Run the activation command as the service user:

```bash
sudo -u adguard env \
  HOME=/var/lib/adguard-cli \
  AG_CLI_DATA_PATH=/var/lib/adguard-cli \
  /usr/bin/adguard-cli activate
```

Follow the interactive prompts and provide the license key or serial number when requested. The activation data is stored in:

```text
/var/lib/adguard-cli/adguard.conf
```

If initial configuration is required, run:

```bash
sudo -u adguard env \
  HOME=/var/lib/adguard-cli \
  AG_CLI_DATA_PATH=/var/lib/adguard-cli \
  /usr/bin/adguard-cli configure
```

Restart the service after activation or configuration:

```bash
sudo systemctl restart adguard-cli.service
```

## Verification and usage

Check the service status:

```bash
systemctl status adguard-cli.service
```

View live service logs:

```bash
sudo journalctl -u adguard-cli.service -f
```

Display the available CLI commands:

```bash
adguard-cli --help
```

## Configuration and data

The system service uses:

```text
User:    adguard
Group:   adguard
Data:    /var/lib/adguard-cli
```

The service explicitly sets:

```text
HOME=/var/lib/adguard-cli
AG_CLI_DATA_PATH=/var/lib/adguard-cli
```

This prevents the service from depending on the home directory of the user who installed the package or on a logged-in interactive user.

## Service management

```bash
sudo systemctl start adguard-cli.service
sudo systemctl stop adguard-cli.service
sudo systemctl restart adguard-cli.service
sudo systemctl enable adguard-cli.service
sudo systemctl disable adguard-cli.service
```

The installed unit is:

```text
/usr/lib/systemd/system/adguard-cli.service
```

The service runs:

```text
/usr/bin/adguard-cli start --no-fork --log-to-file
```

The `--no-fork` option keeps the process under systemd supervision.

## Legacy data migration

When `/var/lib/adguard-cli/adguard.conf` does not exist, the package looks for existing data in:

```text
/opt/adguard/.local/share/adguard-cli
/home/*/.local/share/adguard-cli
```

If a valid `adguard.conf` is found, the data is copied to `/var/lib/adguard-cli` and assigned to `adguard:adguard`.

## Removal

Remove the package while preserving its data:

```bash
sudo apt remove adguard-debian
```

To remove the package and its service data:

```bash
sudo systemctl stop adguard-cli.service
sudo apt purge adguard-debian
sudo rm -rf /var/lib/adguard-cli
```

## Building the package

This repository contains a prepared Debian package tree. Build it from a clean staging directory so repository metadata and root-level documentation are not included in the package:

```bash
staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT
tar --exclude=.git --exclude=.github --exclude=.gitignore \
    --exclude=README.md --exclude=LICENSE \
    -cf - . | tar -xf - -C "$staging_dir"
dpkg-deb --build --root-owner-group \
    "$staging_dir" ../adguard-debian_1.0.0-1_amd64.deb
```

Inspect the generated package with:

```bash
dpkg-deb --info ../adguard-debian_1.0.0-1_amd64.deb
dpkg-deb --contents ../adguard-debian_1.0.0-1_amd64.deb
```

Generated packages and build artifacts are excluded by `.gitignore`.

## Package layout

```text
DEBIAN/
├── control
├── postinst
├── postrm
├── preinst
└── prerm
usr/
├── bin/
│   └── adguard-cli -> /usr/lib/adguard-cli/adguard-cli
└── lib/
    ├── adguard-cli/
    └── systemd/system/
        └── adguard-cli.service
└── share/
    └── doc/
        └── adguard-debian/
            ├── README.md
            ├── changelog.Debian
            └── copyright
```

## Contributing

Bug reports, documentation improvements, and packaging changes are welcome through [GitHub Issues](https://github.com/nilocnt/adguard-debian/issues) and pull requests.

Please do not submit license keys, private configuration files, generated `.deb` files, or other sensitive data.

## License

This packaging project is distributed under the [GNU General Public License v3.0](LICENSE). Upstream AdGuard CLI remain subject to their respective licenses and attribution requirements.

## Links

- [Project repository](https://github.com/nilocnt/adguard-debian)
- [Latest releases](https://github.com/nilocnt/adguard-debian/releases/latest)
- [AdGuard CLI](https://adguard.com/en/adguard-cli/overview.html)
- [AdGuard for Linux official overview](https://adguard.com/en/adguard-linux/overview.html?source=ag_products_page)
- [AdGuard support](https://adguard.com/en/support.html)
