# TurboAsusSec
This is a project attempting to integrate all the security portions of an Asus Merlin router, including Skynet, Diversion &amp; AIProtect.  The inital project will be to view various portions of security on an Asus router, with the plan to allow the user to more easily control some aspects of security on their Asus router.  

This script is mostly AI created, at least initially, how else would you create such a big project???
This script is insprired by the crew at snbforums, including RMERLIN, ADAMM, LONELYCODER & others.  
From AI:

# TurboChargeDivSky - Repository Structure

## Directory Layout

```
TurboChargeDivSky/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── install.sh                      # One-command installer
├── scripts/
│   ├── tcds.sh                     # Main menu & orchestrator
│   ├── tcds-core.sh                # Core utilities & common functions
│   ├── tcds-whitelist.sh           # Whitelist/blocklist management
│   ├── tcds-aiprotect.sh           # AIProtect analysis
│   ├── tcds-threat-db.sh           # CVE & threat database analysis
│   ├── tcds-diagnostics.sh         # System diagnostics
│   ├── tcds-skynet.sh              # Skynet integration functions
│   ├── tcds-diversion.sh           # Diversion integration functions
│   └── tcds-service.sh             # Service event handler
├── webui/
│   ├── tcds.asp                    # Main web interface
│   └── tcds-install-webui.sh       # Web UI installer
├── docs/
│   ├── INSTALL.md
│   ├── USAGE.md
│   ├── API.md
│   └── TROUBLESHOOTING.md
└── .github/
    └── workflows/
        └── release.yml             # GitHub Actions for releases
```

## Installation URL

Users will install with:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/TurboChargeDivSky/master/install.sh | sh
```

Or manual:
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/TurboChargeDivSky/master/install.sh -O /tmp/tcds-install.sh
sh /tmp/tcds-install.sh
```

## Module Design

### tcds.sh (Main)
- Displays menu
- Routes to appropriate module
- Minimal logic, mostly calls other scripts

### tcds-core.sh
- Common functions (logging, colors, cache management)
- Sourced by all other scripts
- Version checking

### tcds-aiprotect.sh
- Device analysis
- CVE list from last 2-5 years
- Simple, focused features

### tcds-threat-db.sh
- BWDPI database parsing
- CVE search
- Threat statistics

### tcds-diagnostics.sh
- System checks
- Integration detection
- Troubleshooting info

## Version Strategy

- **v1.0.x** - Initial releases, bug fixes
- **v1.1.x** - Feature additions (read-only)
- **v1.2.x** - Web UI added
- **v2.0.x** - Modification features (write operations)

## Next Steps

1. Create repository on GitHub
2. I'll provide all files
3. You upload to your repository
4. Test installation
5. Iterate and improve
