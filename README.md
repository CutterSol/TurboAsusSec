# TurboAsusSec **(Beta)**

**Unified Security Management for ASUS Merlin Routers**

⚠️ **This project is in BETA** - Active development, features being tested and refined

Integrate and manage **Skynet** (IP firewall), **Diversion** (DNS blocking), and **AIProtect** (threat detection) from a single, lightweight interface.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://opensource.org/licenses/GPL-3.0)
[![Version](https://img.shields.io/badge/version-1.2.2-green.svg)](https://github.com/CutterSol/TurboAsusSec/releases)
[![Platform](https://img.shields.io/badge/platform-ASUS%20Merlin-red.svg)](https://www.asuswrt-merlin.net/)

---

## 🎯 What Does TurboAsusSec Do?

TurboAsusSec is a **unified security dashboard and management tool** for ASUS routers running Merlin firmware. Instead of managing Skynet, Diversion, and AIProtect separately, you get:

- **Single Interface** - One command (`tcds`) to access everything
- **Merged Views** - See combined whitelists across all security systems
- **Threat Intelligence** - Analyze AIProtect events, CVE signatures, and device security
- **Quick Access** - View logs, check status, run diagnostics instantly
- **Lightweight** - Smart caching minimizes resource usage (~1MB persistent, ~10MB peak)

Think of it as your **security command center** for Merlin routers.

---

## 🚀 Quick Start

### Installation (One Command)

```bash
curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main/install.sh -o /tmp/tcds-install.sh && sh /tmp/tcds-install.sh
```

This downloads and runs the interactive installer. Choose:
- **1** - Install (first time)
- **2** - Update (already installed)
- **3** - Uninstall

### First Run

After installation:
```bash
tcds diagnostics  # Verify everything works
tcds              # Start using the menu
```

---

## 📋 Requirements

### ✅ Required

- **ASUS Router** with Merlin firmware **384.15+**
- **Skynet** - IP-based firewall (REQUIRED - see installation below)
- **SSH access** to your router

### ⚙️ Recommended

- **Diversion** - DNS-based ad/malware blocking (highly recommended)
- **AIProtect** - Built-in threat detection (enable in router settings)
- **Entware** - Package manager for optional tools
- **sqlite3-cli** - For AIProtect database queries

### 📦 Installing Prerequisites

#### Install Skynet (Required)
```bash
/usr/sbin/curl -fsL https://raw.githubusercontent.com/Adamm00/IPSet_ASUS/master/firewall.sh -o /jffs/scripts/firewall
chmod +x /jffs/scripts/firewall
/jffs/scripts/firewall install
```

#### Install Diversion (Recommended)
```bash
amtm
# Select Diversion from menu, follow prompts
```

#### Install sqlite3 (For AIProtect features)
```bash
opkg update
opkg install sqlite3-cli
```
*Note: The installer will offer to auto-install sqlite3 if missing.*

#### Enable AIProtect (Optional)
1. Router Web UI → **AiProtection**
2. Enable **AiProtection**
3. Let it run for a while to populate the database

---

## 💻 Usage Guide

### Interactive Menu

Simply type:
```bash
tcds
```

You'll see:
```
╔══════════════════════════════════════════════════════════════╗
║         TurboAsusSec v1.2.2                                  ║
║      Unified Security Management for ASUS Merlin             ║
╚══════════════════════════════════════════════════════════════╝

Main Menu:

  1) Overview & Statistics
  2) View Merged Whitelist
  3) Add to Whitelist
  4) View Skynet Recent Blocks
  5) AIProtect & Threat Analysis ►
  6) System Diagnostics
  7) Clear Cache
  8) Update Script
  0) Exit

Enter choice:
```

### Command Line Usage

```bash
tcds overview         # Quick system status
tcds diagnostics      # Full system check
tcds whitelist-show   # View merged whitelist
tcds skynet-logs      # Recent Skynet blocks
tcds clear-cache      # Force data refresh
tcds version          # Show version
tcds help             # Show all commands
```

---

## 📖 Feature Descriptions

### 1️⃣ Overview & Statistics

**What it shows:**
- Skynet status and entry counts (whitelist/blacklist)
- Diversion status and entry counts (allowlist/denylist)
- AIProtect database status and event counts
- Custom list statistics

**Use case:** Daily check-in to see security posture at a glance

---

### 2️⃣ View Merged Whitelist

**What it shows:**
- **All whitelisted entries** from Skynet, Diversion, and custom lists
- **Source** for each entry (which system it came from)
- **Type** detection (IP, CIDR, Domain, etc.)
- Automatic paging for large lists (100+ entries)

**Data is cached** for 10 minutes to improve performance.

**Example Output:**
```
Total entries: 247

Entry               Source      Type
────────────────────────────────────────
192.168.1.100      Skynet      IP
192.168.0.0/16     Skynet      CIDR
github.com         Diversion   Domain
speedtest.net      Custom      -
```

**Use case:** Verify what's whitelisted, ensure important services aren't blocked

---

### 3️⃣ Add to Whitelist

**Interactive prompts:**
1. Enter IP or domain
2. Choose target:
   - Skynet only
   - Diversion only
   - Both (recommended for domains)
   - Custom list (for reference only)

**Automatically:**
- Clears cache to show new entry immediately
- Logs the action for audit trail
- Validates input format

**Use case:** Quick whitelist when something important gets blocked

---

### 4️⃣ View Skynet Recent Blocks

**What it shows:**
- Recent BLOCKED entries from Skynet logs
- Configurable number of entries (default: 20)
- Automatically finds log location (USB mount or local)

**Use case:** Check what's being blocked right now, identify false positives

---

### 5️⃣ AIProtect & Threat Analysis ►

**Submenu with 4 options:**

#### Option 1: Show Devices with Security Events
- Lists devices that triggered AIProtect
- Shows count per device (Malicious Sites, IPS Events)
- Severity indicators
- **Use case:** Identify potentially compromised devices

#### Option 2: Analyze Specific Device
- Deep dive into a single device's events
- Shows:
  - Event timeline
  - Sites accessed
  - IPS rules triggered
  - Severity breakdown
- **Use case:** Investigate suspicious device behavior

#### Option 3: Show Recent CVEs (Last 5 Years)
- Browse CVE signatures in your BWDPI threat database
- Year-by-year breakdown
- Shows which vulnerabilities your router can detect
- **Use case:** Understand your threat detection coverage

#### Option 4: Search for Specific CVE
- Enter CVE ID (e.g., CVE-2024-1234)
- Check if your router's database contains it
- Shows rule details if found
- **Use case:** Check if a specific vulnerability is covered

---

### 6️⃣ System Diagnostics

**Comprehensive health check covering:**

#### System Information
- Script version
- Router model and firmware
- Current time and uptime

#### Resource Usage
- Memory usage (MB and percentage)
- JFFS storage space
- /tmp storage space

#### Required Commands
- Checks for ipset, sqlite3, grep, awk, sed, curl
- Shows path if found, warns if missing

#### Skynet Integration
- Installation status and version
- Data path detection (USB or local)
- Log file location and size
- IPSet file status
- Active IPSets and entry counts

#### Diversion Integration
- Installation status
- List directory contents
- Allowlist/denylist/blockinglist status
- File sizes

#### AIProtect Integration
- Database availability and size
- Total event count
- Event type breakdown (Malicious Sites vs IPS)

#### BWDPI Threat Database
- Rule database status
- CVE signature count
- Database size

#### DNS Logs
- Dnsmasq log detection
- Log locations and sizes

#### TurboAsusSec Files
- Custom whitelist/blacklist status
- Activity log status
- Cache directory status and size

#### Permissions Check
- Write access to custom lists
- Script executability

#### Integration Summary
- Active integrations count (X/3)
- Recommendations if something's missing

**Use case:** Troubleshooting, verification after updates, confirming proper installation

---

### 7️⃣ Clear Cache

**What it does:**
- Removes all cached data from `/tmp/tcds/`
- Forces fresh data retrieval on next query

**When to use:**
- After manually changing whitelists in Skynet/Diversion
- If data looks stale
- Troubleshooting display issues

**Cache explanation:**
TurboAsusSec caches expensive operations (like parsing all whitelists) for **10 minutes**. This:
- Reduces router load
- Speeds up repeated queries
- Extends flash storage life
- Uses only RAM (/tmp/tcds clears on reboot)

---

### 8️⃣ Update Script

**What it does:**
- Re-downloads installer from GitHub
- Runs update process
- Shows which files changed
- Preserves your custom whitelists/blacklists

**After update:**
- Exit and restart `tcds` to use new version
- Check changelog in installer output

---

## 🔧 Configuration & Settings

### File Locations

```
/jffs/addons/tcds/                  # Main directory
├── scripts/                        # All modules
│   ├── tcds.sh                    # Main menu
│   ├── tcds-core.sh               # Core functions
│   ├── tcds-aiprotect.sh          # AIProtect analysis
│   ├── tcds-diagnostics.sh        # Diagnostics
│   ├── tcds-whitelist.sh          # Whitelist management (future)
│   └── tcds-service.sh            # Service handler
├── logs/
│   └── tcds.log                   # Activity log (future)
├── custom_whitelist.txt           # Your custom whitelist
└── custom_blacklist.txt           # Your custom blacklist (future)

/tmp/tcds/                          # Cache (RAM, cleared on reboot)
└── *.cache                        # Temporary cache files

/jffs/scripts/tcds                  # Symlink for global access

/jffs/configs/profile.add           # Contains tcds alias
```

### Cache Behavior

**Default:** 10 minutes (600 seconds)

**Why caching matters:**
- Reading IPSets, parsing logs, and merging data is expensive
- Caching prevents excessive disk I/O (extends flash life)
- Uses only RAM (/tmp) - no persistent storage impact
- Clears automatically on router reboot

**Manual control:**
```bash
tcds clear-cache  # Force fresh data now
```

### Settings (Advanced)

TurboAsusSec follows Merlin's Addon API for settings. Settings are stored in `/jffs/addons/custom_settings.txt`.

**View current settings:**
```bash
cat /jffs/addons/custom_settings.txt | grep tcds
```

**Modify settings:**
```bash
. /usr/sbin/helper.sh

# Change cache timeout (in seconds)
am_settings_set tcds_cache_ttl 1800  # 30 minutes

# Disable a feature
am_settings_set tcds_aiprotect_enabled disabled
```

**Available settings:**
- `tcds_version` - Current version (auto-managed)
- `tcds_cache_ttl` - Cache timeout in seconds (default: 600)
- `tcds_aiprotect_enabled` - Enable AIProtect features (default: enabled)

---

## 🐛 Troubleshooting

### Installation Issues

#### Problem: `curl: command not found`
**Solution:**
```bash
opkg update
opkg install curl
```

#### Problem: Scripts fail to download
**Solution:**
```bash
# Test GitHub access
ping github.com

# Check DNS
nslookup github.com

# Try manual download
wget https://github.com/CutterSol/TurboAsusSec/archive/master.zip
```

#### Problem: `Permission denied` errors
**Solution:**
```bash
# Fix script permissions
chmod 755 /jffs/addons/tcds/scripts/*.sh
chmod +x /jffs/scripts/tcds
```

---

### Command Access Issues

#### Problem: `tcds: command not found`
**Solution:**
```bash
# Reload your profile
. /jffs/configs/profile.add

# Or logout and login again via SSH

# Test direct path
/jffs/addons/tcds/scripts/tcds.sh

# Check symlink
ls -la /jffs/scripts/tcds
```

---

### Skynet Integration Issues

#### Problem: "Skynet not installed"
**Solution:**
```bash
# Install Skynet
/usr/sbin/curl -fsL https://raw.githubusercontent.com/Adamm00/IPSet_ASUS/master/firewall.sh -o /jffs/scripts/firewall
chmod +x /jffs/scripts/firewall
/jffs/scripts/firewall install
```

#### Problem: "No Skynet IPSets found"
**Solution:**
```bash
# Start Skynet
firewall start

# Verify IPSets exist
ipset list -n | grep -i skynet

# Run diagnostics
tcds diagnostics
```

#### Problem: "Skynet log file not found"
**Cause:** Skynet stores logs on USB if available, otherwise local storage.

**Solution:**
```bash
# Find Skynet log location
find /tmp/mnt -name "skynet.log" 2>/dev/null
find /jffs -name "skynet.log" 2>/dev/null

# TurboAsusSec should auto-detect, but you can manually check diagnostics
tcds diagnostics
```

---

### Diversion Integration Issues

#### Problem: "Diversion not installed"
**Solution:**
```bash
# Install via amtm
amtm
# Select Diversion from menu
```

#### Problem: "Allowlist not found"
**Cause:** Diversion creates files on first use.

**Solution:**
```bash
# Verify Diversion is running
diversion status

# Manually create if needed
touch /opt/share/diversion/list/allowlist
touch /opt/share/diversion/list/denylist
```

---

### AIProtect Issues

#### Problem: "AIProtect database not available"
**Solution:**
1. Router Web UI → **AiProtection** → **Enable AiProtection**
2. Browse internet for ~10 minutes to generate data
3. Check diagnostics: `tcds diagnostics`

#### Problem: "sqlite3 not available"
**Solution:**
```bash
# Install sqlite3
opkg update
opkg install sqlite3-cli

# Verify installation
which sqlite3
sqlite3 --version
```

#### Problem: "Cannot query database"
**Cause:** Database corruption or permission issues.

**Solution:**
```bash
# Check database integrity
sqlite3 /jffs/.sys/AiProtectionMonitor/AiProtectionMonitor.db "SELECT COUNT(*) FROM monitor;"

# If errors, disable and re-enable AiProtection in router settings
```

---

### Performance Issues

#### Problem: Menu feels slow
**Solution:**
```bash
# Clear cache (forces fresh but fast rebuild)
tcds clear-cache

# Increase cache timeout to reduce refreshes
. /usr/sbin/helper.sh
am_settings_set tcds_cache_ttl 1800  # 30 minutes
```

#### Problem: High memory usage
**Cause:** Very large whitelists or blocklists.

**Solution:**
```bash
# Check sizes
tcds diagnostics

# Clear cache more frequently
tcds clear-cache

# Consider reducing Skynet/Diversion list sizes
```

---

### Data Display Issues

#### Problem: Whitelist shows 0 Skynet entries
**Cause:** IPSet names might be different or Skynet not started.

**Solution:**
```bash
# Check IPSets exist
ipset list -n | grep -i skynet

# Start Skynet
firewall start

# Run diagnostics
tcds diagnostics
```

#### Problem: AIProtect shows MAC addresses instead of device names
**Cause:** Normal - AIProtect database stores MAC addresses.

**Solution:**
- TurboAsusSec will attempt to resolve to hostnames in future updates
- For now, cross-reference with your router's device list

---

## 🔄 Updating TurboAsusSec

### From Menu
```bash
tcds
# Choose option 8 (Update Script)
```

### From Command Line
```bash
curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main/install.sh -o /tmp/tcds-install.sh && sh /tmp/tcds-install.sh
# Choose option 2 (Update)
```

### What Gets Updated
- All script files in `/jffs/addons/tcds/scripts/`
- Symlink verification
- Alias verification
- **Preserved:** Your custom whitelists/blacklists

### After Update
```bash
# Exit and restart tcds to use new version
exit
tcds
```

---

## 🗑️ Uninstallation

### From Menu
```bash
curl -sSL https://raw.githubusercontent.com/CutterSol/TurboAsusSec/main/install.sh -o /tmp/tcds-install.sh && sh /tmp/tcds-install.sh
# Choose option 3 (Uninstall)
# Confirm with 'yes'
```

### What Gets Removed
- `/jffs/addons/tcds/` (entire directory)
- `/jffs/scripts/tcds` (symlink)
- `tcds` alias from `/jffs/configs/profile.add`
- `/tmp/tcds/` (cache directory)

### What's Backed Up
Before removal, your custom whitelists are backed up to:
```bash
/tmp/tcds_backup_YYYYMMDD_HHMMSS/
```

### What's NOT Affected
- Skynet installation and configuration
- Diversion installation and configuration
- AIProtect settings
- Router settings

---

## 🛣️ Roadmap

### Version 1.2.x (Beta - Current)
- [x] Core functionality (Overview, Whitelist View, Diagnostics)
- [x] AIProtect device analysis
- [x] CVE signature browsing
- [x] Skynet log viewing
- [x] Smart caching system
- [x] Interactive installer
- [x] Update mechanism
- [ ] Device name resolution (IP → hostname)
- [ ] Enhanced DNS log correlation
- [ ] Export functionality

### Version 1.3.0 (Stable Release - Q1 2025)
- [ ] SNBForums release thread
- [ ] Web UI integration (router admin panel)
- [ ] Backup/restore functionality
- [ ] More detailed threat statistics
- [ ] Automated testing suite
- [ ] Multi-language support (starting with English/Spanish)

### Version 1.4.0 (Enhanced Features - Q2 2025)
- [ ] Log download feature
- [ ] Visual dashboards and charts
- [ ] Email/notification system
- [ ] Scheduled reports
- [ ] Historical trend analysis

### Version 2.0.0 (Full Management - Future)
- [ ] Modification features (add/remove from Skynet/Diversion via UI)
- [ ] Sync between Skynet and Diversion
- [ ] Automated threat response rules
- [ ] Integration with external threat feeds
- [ ] Community blocklist sharing

---

## 🤝 Contributing

We welcome contributions! This project is AI-assisted development in collaboration with the community.

### Ways to Contribute

1. **Bug Reports**
   - Use [GitHub Issues](https://github.com/CutterSol/TurboAsusSec/issues)
   - Include: Router model, firmware version, steps to reproduce
   - Run `tcds diagnostics` and include output

2. **Feature Suggestions**
   - Open a GitHub Issue with "Feature Request" label
   - Explain use case and expected behavior

3. **Testing**
   - Test on different router models
   - Test with different integration combinations
   - Report results in Issues

4. **Code Contributions**
   - Fork the repository
   - Create a feature branch
   - Submit a pull request
   - Follow existing code style (POSIX shell)

### Testing Feedback Needed

Help us test:
- **Router Models**: RT-AX86U, RT-AX88U, RT-AC68U, RT-AC86U, others?
- **Firmware Versions**: 388.x, 386.x
- **Integration Combos**: Skynet only, Skynet+Diversion, all three
- **Memory Constraints**: Low-memory devices (256MB RAM)

### Development Team

- **Architect**: CutterSol
- **Senior Developer**: Claude (Anthropic)
- **Developer**: Gemini (Google)

---

## 📜 License

**GNU General Public License v3.0**

See [LICENSE](LICENSE) file for full details.

**TL;DR:**
- ✅ Free to use, modify, and distribute
- ✅ Commercial use allowed
- ⚠️ Must disclose source if distributed
- ⚠️ Must maintain same license (GPL-3.0)
- ⚠️ No warranty or liability

---

## 🙏 Credits & Acknowledgments

### Built Upon Excellent Work By

- **[RMerlin](https://www.asuswrt-merlin.net/)** - ASUS Merlin Firmware
- **[Adamm](https://github.com/Adamm00)** - Skynet Firewall
- **[thelonelycoder](https://diversion.ch/)** - Diversion Ad Blocker
- **[Trend Micro](https://www.trendmicro.com/)** - AIProtect/BWDPI Engine

### Community Support

- **[SNBForums](https://www.snbforums.com/)** - Endless help, testing, and knowledge
- **ASUS Merlin Community** - Bug reports, feature requests, and encouragement

### Technology Partners

- **[Anthropic](https://www.anthropic.com/)** - Claude AI (Senior Developer)
- **[Google](https://ai.google/)** - Gemini AI (Developer)
- **GitHub** - Code hosting and collaboration

### Special Thanks

- All beta testers
- Everyone who reported bugs
- Community members who provided feedback
- Open source contributors

---

## 📞 Support & Community

### Get Help

- **Documentation**: [GitHub Wiki](https://github.com/CutterSol/TurboAsusSec/wiki) *(coming soon)*
- **Issues**: [GitHub Issues](https://github.com/CutterSol/TurboAsusSec/issues)
- **Forum**: [SNBForums Thread](https://www.snbforums.com/) *(coming soon)*

### Stay Updated

- **Watch** this repository for release notifications
- **Star** if you find it useful
- **Fork** to contribute or customize

---

## ⚠️ Disclaimer

### Important Notices

1. **Beta Software**
   - This is BETA software under active development
   - Features may change
   - Bugs may exist
   - Test before deploying in production environments

2. **Security Responsibility**
   - TurboAsusSec enhances visibility but doesn't replace proper security practices
   - **Always:**
     - Keep firmware updated
     - Use strong passwords (20+ random characters)
     - Enable WPA3 if supported
     - Monitor your network regularly
     - Keep backups of configurations

3. **No Warranty**
   - Provided AS-IS without warranty of any kind
   - Not responsible for data loss, security breaches, or router issues
   - Use at your own risk

4. **Not Affiliated**
   - Not affiliated with ASUS, RMerlin, Skynet, Diversion, or Trend Micro
   - Unofficial third-party tool

5. **Flash Wear**
   - Minimizes writes to flash storage through smart caching
   - Still, any script involves some storage operations
   - JFFS has limited write cycles (~100,000)

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| **Current Version** | 1.2.2 (Beta) |
| **Release Date** | December 2025 |
| **License** | GPL-3.0 |
| **Language** | POSIX Shell |
| **Platform** | ASUS Merlin 384.15+ |
| **Memory Footprint** | ~1MB persistent, ~10MB peak |
| **Dependencies** | Skynet (required), Diversion (recommended), sqlite3 (optional) |

---

## 🏆 Project Goals

### Short-term (v1.2.x - Beta)
- ✅ Stable core functionality
- ✅ Comprehensive diagnostics
- ✅ Merged whitelist viewing
- ✅ AIProtect analysis
- 🔄 **In Progress:** Device name resolution, enhanced logging

### Mid-term (v1.3.x - Stable)
- 🎯 **Ready for SNBForums release**
- 🎯 Web UI integration
- 🎯 Backup/restore
- 🎯 100% test coverage

### Long-term (v2.0+ - Full Featured)
- 🚀 Complete management interface
- 🚀 Automated threat response
- 🚀 Community feature contributions
- 🚀 Integration with external threat intelligence

---

**Made with ❤️ and 🤖 for the ASUS Merlin community**

---

*Last Updated: December 5, 2025*  
*Version: 1.2.2 Beta*  
*Tested On: RT-AX86U with Merlin 388.x*
