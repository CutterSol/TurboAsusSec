# TurboAsusSec **(Beta)**

**Unified Security Management for ASUS Merlin Routers**

⚠️ **This project is in BETA** - Active development, features being tested

Integrate and manage Skynet, Diversion, and AIProtect from a single, lightweight interface.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/CutterSol/TurboAsusSec/releases)

---

## 🎯 Features

- **Unified Dashboard**: View security status across all systems in one place
- **AIProtect Analysis**: 
  - View devices triggering security events
  - Browse CVEs from the last 5 years in your threat database
  - Search for specific vulnerabilities
- **Whitelist Management**: Merged view of whitelists across Skynet and Diversion
- **Skynet Log Viewing**: Quick access to recent blocks
- **System Diagnostics**: Comprehensive integration and health checks
- **Lightweight**: Minimal resource usage with smart caching
- **Modular Design**: Only loads features you need

---

## 📋 Requirements

### Minimum Requirements
- ASUS router with Merlin firmware **384.15+**
- At least one of: **Skynet** or **Diversion**
- SSH access to router

### Optional Components
- **Skynet** - IP-based firewall blocking
- **Diversion** - DNS-based ad/malware blocking  
- **AIProtect** - Trend Micro threat detection (built into firmware)
- **sqlite3** - For AIProtect database queries (install via Entware)

### Recommended Setup
```bash
# If you don't have sqlite3 (needed for AIProtect features)
opkg update
opkg install sqlite3-cli
```

---

## 🚀 Installation

### Interactive Installer (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main/install.sh -o /tmp/tcds-install.sh && sh /tmp/tcds-install.sh
```

This opens an interactive menu where you can:
- Install TurboAsusSec
- Update to latest version
- Uninstall completely

### Post-Installation

After installation completes:

```bash
# Run diagnostics to verify everything is working
tcds diagnostics

# Start using the interactive menu
tcds
```

---

## 💻 Usage

### Interactive Menu

Simply run:
```bash
tcds
```

### Command Line

```bash
tcds overview         # Show system overview
tcds diagnostics      # Run full diagnostics  
tcds whitelist-show   # View merged whitelist
tcds skynet-logs      # View recent Skynet blocks
tcds clear-cache      # Clear all cached data
tcds version          # Show version
tcds help             # Show help
```

---

## 📖 Menu Options

### 1. Overview & Statistics
- Quick view of Skynet, Diversion, and AIProtect status
- Entry counts for whitelists and blocklists
- System health at a glance

### 2. View Merged Whitelist
- Combined whitelist from Skynet, Diversion, and custom entries
- Shows source for each entry
- Cached for performance

### 3. Add to Whitelist
- Add IPs or domains to whitelist
- Choose target: Skynet, Diversion, both, or custom
- Interactive prompts guide you through the process

### 4. View Skynet Recent Blocks
- See recent blocked connections
- Configurable number of entries
- Real-time log viewing

### 5. AIProtect & Threat Analysis ►
**Submenu with:**
- **Show Devices with Security Events** - Which devices triggered alerts
- **Analyze Specific Device** - Deep dive into a single device
- **Show Recent CVEs (Last 5 Years)** - Browse your threat database
- **Search for Specific CVE** - Check if router can detect a vulnerability

### 6. System Diagnostics
- Comprehensive system checks
- Integration detection and validation
- Resource usage monitoring
- File and permission verification

### 7. Clear Cache
- Clears all cached data
- Forces fresh data retrieval on next query

---

## 🔧 Configuration

### File Locations

```
/jffs/addons/tcds/                  # Main installation directory
├── scripts/                        # All script modules
│   ├── tcds.sh                    # Main menu
│   ├── tcds-core.sh               # Core functions
│   ├── tcds-aiprotect.sh          # AIProtect module
│   ├── tcds-diagnostics.sh        # Diagnostics
│   └── tcds-service.sh            # Service handler
├── logs/
│   └── tcds.log                   # Activity log
├── custom_whitelist.txt           # User whitelist
└── custom_blacklist.txt           # User blacklist

/tmp/tcds/                          # Cache directory (cleared on reboot)
└── *.cache                        # Cached data files

/jffs/scripts/tcds                  # Symlink for easy access
```

### Settings

Settings are stored using Merlin's Addon API in `/jffs/addons/custom_settings.txt`:

```
tcds_version 1.2.0
tcds_skynet_sync enabled
tcds_diversion_sync enabled
tcds_aiprotect_enabled enabled
tcds_cache_ttl 600
```

Modify with:
```bash
. /usr/sbin/helper.sh
am_settings_set tcds_cache_ttl 1200  # 20 minutes
```

---

## 🐛 Troubleshooting

### Installation Fails

**Problem**: Scripts fail to download

**Solution**:
```bash
# Check internet connectivity
ping github.com

# Try manual download
wget https://github.com/CutterSol/TurboAsusSec/archive/master.zip
```

### AIProtect Features Don't Work

**Problem**: "AIProtect database not available"

**Solution**:
1. Enable AiProtect in router: **AiProtection > Enable AiProtection**
2. Generate some traffic to create database
3. Run `tcds diagnostics` to verify

**Problem**: "sqlite3 not available"

**Solution**:
```bash
opkg update
opkg install sqlite3-cli
```

### Skynet Integration Issues

**Problem**: "Skynet not installed"

**Solution**:
```bash
# Install Skynet
curl -s https://raw.githubusercontent.com/Adamm00/IPSet_ASUS/master/firewall.sh -o /jffs/scripts/firewall
chmod +x /jffs/scripts/firewall
/jffs/scripts/firewall install
```

### Diversion Integration Issues

**Problem**: "Diversion not installed"

**Solution**: Install Diversion via amtm:
```bash
amtm
# Choose Diversion from menu
```

### Memory or Performance Issues

**Solution**:
```bash
# Clear cache more frequently
tcds clear-cache

# Check resource usage
tcds diagnostics

# Increase cache TTL to reduce refreshes
. /usr/sbin/helper.sh
am_settings_set tcds_cache_ttl 1800  # 30 minutes
```

---

## 🔄 Updating

```bash
# Re-run installer to update
curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/master/install.sh | sh

# Or use update command
/jffs/addons/tcds/scripts/../install.sh update
```

---

## 🗑️ Uninstallation

```bash
curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/master/install.sh | sh -s uninstall
```

Your custom whitelists/blocklists will be backed up to `/tmp/tcds_backup`

---

## 🛣️ Roadmap

### v1.3 (Planned)
- [ ] Enhanced DNS log correlation
- [ ] Export logs for SIEM integration
- [ ] Backup/restore functionality
- [ ] More detailed threat statistics

### v1.4 (Planned)
- [ ] Web UI integration
- [ ] Log download feature
- [ ] Visual dashboards

### v2.0 (Future)
- [ ] Modification features (add/remove from lists)
- [ ] Sync between Skynet and Diversion
- [ ] Automated threat response

---

## 🤝 Contributing

Contributions welcome! This project is primarily AI-assisted development in collaboration with the community.

### Ways to Contribute
- Report bugs via [GitHub Issues](https://github.com/CutterSol/TurboAsusSec/issues)
- Suggest features
- Test on different router models
- Submit pull requests

### Testing Feedback Needed
- Router models tested on
- Firmware versions
- Integration combinations (Skynet only, Diversion only, both, etc.)
- Performance on low-memory devices

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

---

## 🙏 Credits

### Inspired By
- **RMerlin** - ASUS Merlin firmware
- **Adamm** - Skynet firewall
- **thelonelycoder** - Diversion ad blocker
- **Trend Micro** - AIProtect/BWDPI
- **SNBForums Community** - Endless support and knowledge

### Built With
- AI-assisted development (Claude by Anthropic)
- Community feedback and testing
- Open source spirit of SNBForums

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/CutterSol/TurboAsusSec/issues)
- **Forum**: [SNBForums Thread](https://www.snbforums.com/) (coming soon)
- **Documentation**: [Wiki](https://github.com/CutterSol/TurboAsusSec/wiki) (coming soon)

---

## ⚠️ Disclaimer

This tool is provided as-is. While it's designed to enhance security visibility, it does not replace proper network security practices. Always:
- Keep firmware updated
- Use strong passwords
- Enable WPA3 if supported
- Monitor your network regularly

---

**Version**: 1.2.0  
**Last Updated**: December 2, 2025  
**Tested On**: RT-AX86U, RT-AX88U with Merlin 388.x

**Made with ❤️ and 🤖 for the ASUS Merlin community**
