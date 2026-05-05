# Homebrew Tap Status

## Current state (2026-05-04 PM, Option 3 decision)

**Path A (canonical for stage demo + most customers): direct download from the portal.** Customers receive a one-liner in their license email that resolves through the portal's signed-URL endpoint to R2:

```bash
export HADES_LICENSE_KEY="<paste from portal email>"
curl -fL -H "Authorization: Bearer $HADES_LICENSE_KEY" \
  "https://portal.darkhorseinfosec.com/api/v1/download/linux-x86_64/v1.4.2/hades" \
  -o hades && chmod +x hades
```

This path is certified working as of 2026-05-04 (auth + signed-URL probes 9/9 PASS in `tasks/installation_ux_test_2026-05-04.md`). Path A is what the DEFCON ThinkPad will use on stage. The curl-in-/tmp visual is more demo-impressive than `brew install`.

**Path B (Homebrew tap for hallway-track / SOC analyst convenience): DEFERRED, on GitHub.** Decision logged 2026-05-04 PM:

- The Homebrew tap will live at **`github.com/darkhorse-infosec/homebrew-tap`** (a NEW public repo separate from any HADES code repo). NOT on Forgejo. Reasons:
  1. Homebrew users expect taps on GitHub by convention; `brew tap darkhorse-infosec/tap` resolves there with no explicit URL.
  2. Forgejo is where private HADES code lives; mixing public tap content into the same self-hosted Forgejo instance creates confusion (and risks making customers think the HADES source is also visible there).
  3. The tap repo content is metadata-only — just `Formula/hades-scanner.rb` (~50 lines of Ruby) — so it's safe to put on GitHub. The actual binary download is still license-gated through the portal + R2.

## What the tap repo would contain (and not contain)

Tap repo = the formula RECIPE, not the binary or the source.

```
github.com/darkhorse-infosec/homebrew-tap/
└── Formula/
    └── hades-scanner.rb       ← copy of THIS repo's Formula/hades-scanner.rb
```

The formula's `url` points to `portal.darkhorseinfosec.com/api/v1/download/...`, gated by `HOMEBREW_HADES_LICENSE_KEY`. NOTHING proprietary lands in the tap repo.

## Operator runbook to ship Path B (when ready)

**Prerequisites Domenic owns:**

1. A GitHub Personal Access Token (DIFFERENT from the Forgejo PAT). Generate at `github.com/settings/tokens` with `repo` scope for `darkhorse-infosec`. Save to `D:/Projects/.ssh/RW_GITHUB_PAT_<date>.txt` (mode 600) per the existing PAT-storage convention.

2. A decision: same name `homebrew-tap`, or branded `homebrew-darkhorse` etc.? Default: `homebrew-tap` (Homebrew convention).

**Steps once those are ready (~5 min, Claude can drive given the GitHub PAT):**

1. Create public repo `github.com/darkhorse-infosec/homebrew-tap` (via `gh` CLI or GitHub UI).
2. Copy `Formula/hades-scanner.rb` from THIS HADES repo into the tap repo.
3. Commit + push.
4. Test from a clean Mac (or the DEFCON ThinkPad once it arrives):
   ```bash
   brew tap darkhorse-infosec/tap
   export HOMEBREW_HADES_LICENSE_KEY="<your real Pro+ key>"
   brew install hades-scanner
   hades --version  # expect: HADES Enhanced Detection Engine v1.4.2
   ```
5. On every HADES binary release: bump `Formula/hades-scanner.rb` here AND mirror to the tap repo (or set up a Forgejo Action to mirror automatically). Currently mirror is manual; automation is a v2.0+ chore.

## Why we're NOT putting the tap on Forgejo

The Forgejo PAT we have today (`D:/Projects/.ssh/RW FORGEJO API TOKEN 050426.txt`) only grants access to `DarkHorse/darkhorse-hades` (the private code repo). Even if we created a separate `darkhorse-infosec/homebrew-tap` repo on Forgejo and made it public, every customer who ran `brew tap darkhorse-infosec/tap` would discover that the same Forgejo instance ALSO hosts proprietary HADES code at `DarkHorse/darkhorse-hades`. They'd find a sign-in prompt instead of a 404, which is itself a tell.

Putting the tap on a completely different host (GitHub) avoids the entire problem. Customers see GitHub for the tap; portal for the binary; they have no reason to ever know Forgejo exists.

## Related work

- Customer license email install one-liner: `portal/email.py` in the portal repo (uses `CURRENT_VERSION` from `portal/routes/download.py:38`)
- Path A acceptance test runbook: `tasks/installation_ux_test_runbook.md`
- Path A 9/9 structural cert: `tasks/installation_ux_test_2026-05-04.md` Probe B
- Tier 4 cron operator runbook: `docs/.internal/tier4_sync_runbook.md`
