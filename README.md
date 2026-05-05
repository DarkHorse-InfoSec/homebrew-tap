# DarkHorse InfoSec Homebrew Tap

Homebrew tap for [DarkHorse Information Security LLC](https://darkhorseinfosec.com) tools.

## Install HADES Scanner

```bash
brew tap DarkHorse-InfoSec/tap
brew install DarkHorse-InfoSec/tap/hades-scanner
```

Or one-liner:

```bash
brew install DarkHorse-InfoSec/tap/hades-scanner
```

A valid HADES Pro+ license key is required at install time. Set it via:

```bash
export HOMEBREW_HADES_LICENSE_KEY="<your-key>"
brew install DarkHorse-InfoSec/tap/hades-scanner
```

The formula calls the HADES portal at `dl.darkhorseinfosec.com`, validates your license, and downloads the signed binary directly.

## About HADES

HADES (Hidden Artifact Detection & EXIF Scanner) is an enterprise metadata-forensics and malware-detection engine. Read more at [darkhorseinfosec.com](https://darkhorseinfosec.com).

Licenses are sold via [portal.darkhorseinfosec.com](https://portal.darkhorseinfosec.com).
