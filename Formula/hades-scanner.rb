# Formula/hades-scanner.rb
# Homebrew formula for HADES -- Metadata Forensics Engine
# Copyright (c) DarkHorse Information Security LLC
#
# Distribution: license-gated via the DarkHorse customer portal.
# The portal verifies an active subscription before issuing a 15-minute signed
# download URL on dl.darkhorseinfosec.com (R2 + hades-dl Cloudflare Worker).
#
# Install:
#   1. Set your license key:
#        export HOMEBREW_HADES_LICENSE_KEY="<paste from your portal email>"
#      (HADES_LICENSE_KEY also accepted for parity with the runtime.)
#   2. Tap and install:
#        brew tap DarkHorse-InfoSec/tap
#        brew install hades-scanner
#
# Without HOMEBREW_HADES_LICENSE_KEY, the install fails with a clear message
# pointing to the portal.

require "download_strategy"

class HadesPortalDownloadStrategy < CurlDownloadStrategy
  def _curl_args
    args = super
    license = ENV["HOMEBREW_HADES_LICENSE_KEY"] || ENV["HADES_LICENSE_KEY"]
    if license.nil? || license.strip.empty?
      raise CurlDownloadStrategyError, <<~ERROR
        HADES is license-gated. Set your license key first:
          export HOMEBREW_HADES_LICENSE_KEY="<paste from your portal email>"
        Then retry:
          brew install hades-scanner
        Don't have a license? Buy one at https://darkhorseinfosec.com/hades.html
      ERROR
    end
    args + ["-H", "Authorization: Bearer #{license.strip}", "-L"]
  end
end

class HadesScanner < Formula
  desc "Enterprise metadata forensics and malware detection engine"
  homepage "https://darkhorseinfosec.com/hades.html"
  license :cannot_represent
  version "1.4.3"

  on_linux do
    on_intel do
      url "https://portal.darkhorseinfosec.com/api/v1/download/linux-x86_64/v1.4.3/hades",
          using: HadesPortalDownloadStrategy
      # sha256 from Nuitka build on VM 2026-05-02 23:37 UTC, duration ~5000s.
      # Binary size 1,328,477,290 bytes. Uploaded to R2 2026-05-03 03:06 UTC.
      sha256 "b9da611962ae36c09eb5350841cc08e8b34d413481a291f08451166512fa960f"  # pragma: allowlist secret
    end
  end

  # macOS + Windows builds ship in v1.4.x as builds become available.
  # See tasks/v1_4_1_r2_distribution_plan.md for the build matrix.

  def install
    bin.install "hades"
  end

  def post_install
    (var/"hades").mkpath
    ohai "HADES v#{version} installed. Activate your license:"
    ohai "  export HADES_LICENSE_KEY=\"<your key>\""
    ohai "Manage your license + downloads: https://portal.darkhorseinfosec.com/dashboard"
  end

  def caveats
    <<~EOS
      HADES v#{version} -- Enterprise Metadata Forensics Engine

      Without a license key, HADES runs in community mode:
        - 10 scans/month
        - Heuristic + IOC analysis only (no YARA, no ML)

      To activate your license:
        export HADES_LICENSE_KEY="your-key-here"
        hades admin license

      Quick start:
        hades scan suspicious_file.exe
        hades serve --port 8666
    EOS
  end

  test do
    assert_match "HADES", shell_output("#{bin}/hades --version 2>&1", 0)
  end
end
