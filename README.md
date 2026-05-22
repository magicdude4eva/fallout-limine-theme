# Fallout Limine Theme

A retro-futuristic Fallout-themed bootloader configuration for the Limine bootloader on Arch Linux and CachyOS.

Features the iconic Fallout aesthetic with green terminal text (#67d97a) on a black background with Fallout splash art.

## Features

- 🎮 Fallout-inspired green-on-black color scheme
- 🖼️ Fallout splash artwork wallpaper
- 🔒 BLAKE2 (b2sum) verified splash image integrity
- 📦 Arch Linux / CachyOS optimized with pacman support
- ⚙️ Micro editor integration for easy configuration
- 💾 Automatic backup before modifications
- 🔄 Easy installation and removal

## Installation

### Prerequisites

- Arch Linux or CachyOS
- Limine bootloader installed and configured
- Root access

### Quick Install

1. Clone this repository:
```bash
git clone https://github.com/magicdude4eva/fallout-limine-theme.git
cd fallout-limine-theme
```

2. Run the installer:
```bash
sudo bash setup.sh
```

3. Select option **1) Install theme** from the menu

4. The script will automatically:
   - Copy the splash image to `/boot/`
   - Calculate the b2sum hash
   - Configure your `limine.conf`
   - Prompt for reboot

### Manual Installation

If you prefer to set it up manually:

1. Copy the splash image:
```bash
sudo cp splash.png /boot/
```

2. Calculate the hash:
```bash
sudo b2sum /boot/splash.png
```

3. Add to your `limine.conf`:
```ini
term_palette: 000000;ff0000;67d97a;ffff00;0000ff;ff00ff;67d97a;ffffff
term_palette_bright: 333333;ff0000;67d97a;ffff00;0000ff;ff00ff;67d97a;ffffff
term_background: 000000
term_foreground: 67d97a
term_background_bright: 000000
term_foreground_bright: ffffff
timeout: 10
interface_branding: Fallout
default_entry: 1
wallpaper: boot():/splash.png#<YOUR_B2SUM_HASH_HERE>
```

## Menu Options

When running `sudo bash setup.sh`:

1. **Install theme** - Install the Fallout theme configuration
2. **Remove theme and restore backup** - Revert to previous configuration
3. **Edit limine.conf manually** - Open configuration in micro editor
4. **Show current theme configuration** - Display current settings
5. **Exit** - Close the installer

## Requirements

- `b2sum` - for hash verification (usually in `coreutils` package)
- `sed`, `mktemp`, `grep` - standard Unix tools
- `micro` - text editor (optional, for manual editing)

The script will prompt to install missing dependencies via pacman.

## Color Scheme

The theme uses the classic Fallout color palette:

- **Primary text**: `#67d97a` (Fallout Green)
- **Background**: `#000000` (Black)
- **Bright text**: `#ffffff` (White)

## Backup & Recovery

Before installation, the script automatically creates a backup:

```
/boot/limine.conf.bak-fallout
```

You can restore it at any time using option **2) Remove theme and restore backup**.

## Uninstallation

Run the installer and select option **2) Remove theme and restore backup** to uninstall.

## License

MIT License - See LICENSE file for details

Original Fallout GRUB theme by [shvchk](https://github.com/shvchk/fallout-grub-theme)

## Credits

- Fallout theme concept based on [fallout-grub-theme](https://github.com/shvchk/fallout-grub-theme)
- Inspired by [cachyos-limine-theme](https://github.com/diegons490/cachyos-limine-theme)
- Limine bootloader: https://limine-bootloader.org/

## Support

For issues, questions, or suggestions, please open an issue on GitHub.