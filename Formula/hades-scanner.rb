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
  # Track the version the portal actually SERVES, not the newest one built.
  # Bump this only in lockstep with the R2 upload plus the portal cutover.
  #
  # THIS FILE IS PUBLISHED IN TWO PLACES and customers only read the second:
  #   1. Formula/hades-scanner.rb in the HADES repo (this copy, the source), and
  #   2. github.com/DarkHorse-InfoSec/homebrew-tap, which `brew tap` installs.
  # Copy this file to the tap verbatim on every bump. The tap served 1.4.3 from
  # 2026-05-11 to 2026-09-29 because every "Homebrew cutover" in between
  # (v1.5.x through v1.7.1) edited only copy 1.
  #
  # 2026-10-01: R2 s3://hades-releases/v1.7.3/ holds all 6 objects, verified
  # by streaming the stored bytes back (4/4 MATCH) and by fetching each one
  # through the REAL customer path and hashing the bytes that came back (4/4
  # MATCH). The portal cutover to CURRENT_VERSION=v1.7.3 accompanies this bump,
  # verified by reading the constant out of the RUNNING container and by
  # asking the live portal what it tells an authenticated customer (latest ->
  # v1.7.3 served byte-for-byte).
  version "1.7.3"

  on_linux do
    on_intel do
      url "https://portal.darkhorseinfosec.com/api/v1/download/linux-x86_64/v1.7.3/hades",
          using: HadesPortalDownloadStrategy
      # v1.7.3 Linux artifact (HADES commit 7db18ee). Size 731,993,665 bytes.
      #
      # This hash was NOT copied from a document. It was verified END TO END on
      # 2026-10-01 by fetching this exact object through the real customer path
      # (portal-signed URL -> dl.darkhorseinfosec.com -> Worker -> R2) and
      # sha256'ing the bytes that came back: 731,993,665 B, MATCH.
      # Evidence: dist/build_ea6fde4/BUILD_RECORD_ea6fde4.md ("SHIP 2026-10-01").
      # Size dropped from 1.7.2's 1,347,232,268 B because 1.7.3 excludes the
      # pandas/pyarrow/psycopg2/pi_heif/pillow_heif/tkinter/openpyxl stack.
      #
      # Prior history, why that matters: the version string here was bumped
      # release after release while the sha256 was carried forward untouched,
      # so from v1.4.4 onward no tagged formula carried its own matching hash
      # until v1.5.4 fixed it. Verify against the artifact when bumping. Do not
      # carry forward.
      sha256 "9f512e3fcb4cd18516a08e35933c33602076319a28c1ee05e9026a226d03cc51"  # pragma: allowlist secret
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
