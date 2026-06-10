# Machine Audit — Findings (Phase 1)

**Baseline taken:** 2026-06-10, on battery. Raw data: `audit-data/` (local only).
Caveat: sample taken with active Claude sessions; final before/after will use a
quieter sample. Headline numbers: boot 26.1s (15.9s userspace), 333 processes,
3.3 GB RAM used, 397 wakeups/s.

Approve rows by ID ("all of A, B except B3"). Nothing is touched without a yes.
Every change gets its revert command logged here when applied.

## Group A — Safe: dead weight with no function on this machine

| ID | What it is | Cost | Why remove | You lose |
|----|-----------|------|-----------|----------|
| A1 | **VM guest tools autostarts** (`vboxclient`, `vmware-user`, `spice-vdagent`) — helpers that only do anything when Fedora runs *inside* VirtualBox/VMware/virt-viewer. This is real hardware. | 3 autostart launches per login | Useless on bare metal; pure leftover | Nothing |
| A2 | **rsyslog** — a second logging daemon writing the same logs journald already keeps. Fedora stopped shipping it by default years ago. | constant duplicate disk writes; ~5 MB RAM | Double-logging; journald is the system of record | Plain-text `/var/log/messages` (journalctl has it all) |
| A3 | **SELinux Troubleshooter applet** (`sealertauto`) — tray popup for SELinux denials. | 1 process + python runtime per login | You read denials with journalctl if ever needed; popup noise | Desktop popups on SELinux denials |
| A4 | **abrt Problem Reporting applet** (`org.freedesktop.problems.applet`) — "send crash report to Fedora" tray popup. | 1 process per login + abrt dbus service | Crash dumps still recorded by abrtd; only the popup goes | The popup asking to report crashes |
| A5 | **switcheroo-control** — service for laptops with two GPUs (Intel+NVIDIA). Your i5-1135G7 has one GPU. | 1 service, small | No second GPU exists | Nothing |
| A6 | **sssd-kcm + gssproxy** — enterprise Kerberos/Active-Directory credential plumbing. Home machine, no domain. | 2 services | Never used outside corporate networks | Nothing (re-enables if you ever join a domain) |
| A7 | **imsettings** autostart — input-method framework glue. IBus was removed 2026-05-31; niri xkb handles Hebrew/English. | 1 launch per login | Its framework is already gone | Nothing |

## Group B — Safe for *your* profile (per your answers)

| ID | What it is | Cost | Why remove | You lose |
|----|-----------|------|-----------|----------|
| B1 | **geoclue + demo agent** — WiFi-based location daemon. Only real consumer is darkman (sunset/sunrise). | location polling + 1 autostart | darkman gets fixed Tel-Aviv-area coordinates in its config first, then geoclue idles forever | Auto-timezone when traveling; GNOME Maps blue dot |
| B2 | **GNOME Online Accounts + Evolution Data Server** (`gnome-online-accounts`, `evolution-data-server`, `evolution-ews`, Evolution-alarm-notify autostart) — syncs Google calendar/contacts into GNOME apps you're removing. You didn't know it existed. | 3 running services + 1 autostart, ~30–60 MB across processes | Unused sync machinery; you use Google in the browser | Calendar alarms from synced accounts (you have none) |
| B3 | **Printing/scanning stack** (`cups`, `cups-browsed`, `sane`) — you don't print. | 2 services + printer discovery traffic | Unused | Printing. Reinstall takes one command if you ever buy a printer |
| B4 | **GNOME apps you pick** — Maps, Contacts, Calendar, Clocks, Connections, gnome-remote-desktop, gnome-initial-setup, gnome-classic-session, Characters, Font Viewer, Calculator, gnome-tour, yelp. Boxes/keyring/shell stay. | ~hundreds of MB disk, faster updates; Maps/Contacts pull runtime libs | Unused apps; each removal dry-run checked against deps | The apps you tick. Tell me which to KEEP (e.g. Calculator, Clocks?) |
| B5 | **localsearch / tracker indexer** (`localsearch-3` autostart) — background file-content indexer powering GNOME Files search. You use Thunar + fzf. | periodic disk crawling + RAM; the classic "why is my disk busy" daemon | Nothing in your workflow queries its index | Instant content-search inside GNOME Files (which you don't use) |

## Group C — Judgment calls (read, then decide)

| ID | What it is | Cost | Trade-off |
|----|-----------|------|-----------|
| C1 | **Three out-of-memory killers run simultaneously**: `earlyoom` (your deliberate choice, tuned in `system/`), `systemd-oomd` (Fedora default), `low-memory-monitor`. | 2 redundant monitors polling memory | Keep earlyoom, disable the other two → one clear owner of OOM policy (recommended). Or keep oomd and drop earlyoom — but your config says earlyoom is the choice |
| C2 | **avahi-daemon** — local-network discovery (mDNS). Printers (gone), Chromecast-style discovery, `.local` hostnames. LocalSend does its own discovery and does NOT need it. | 1 service + network chatter | Disable if you never use `.local` names or network discovery. Keep if unsure — cost is small |
| C3 | **plymouth boot splash** — the spinning logo at boot. `plymouth-quit-wait` was the #1 boot delay (6.4s) — but that number was it waiting for GDM. greetd may shrink it naturally. | up to ~6s of boot, re-measured after greetd reboot | Verdict deferred: re-measure first. If still slow: removing it = faster boot, but boot shows text messages instead of the logo (you said no ugly — your call) |
| C4 | **mcp-duckduckgo** (:18800) — zero connections observed; 7 days of logs show only startups. | 1 node process resident | Looks abandoned. Confirm nothing of yours is configured to call it, then disable |
| C5 | **orca screen-reader autostart** — accessibility; exits quickly if unused. | one launch per login | Harmless to keep; removal is cosmetic cleanliness only |
| C6 | **atd** — runs `at` one-shot scheduled jobs; almost nobody uses it. | 1 tiny service | Disable for cleanliness or keep; negligible either way |

## Explicitly KEEP (verified, not touched)

asusd (ASUS hardware control), bolt (Thunderbolt), iio-sensor-proxy (your
Zenbook is a flip — rotation/ambient-light), smartd (disk health), thermald,
TLP, firewalld, Proton VPN split-tunnel, bluetooth, earlyoom, gnome-keyring,
gnome-shell + gnome-session (emergency desktop), Boxes + libvirt, all portals
pending C-group verification, hermes-gateway, codex-update-manager, elephant,
darkman, all niri-session daemons.

## Expected impact (honest)

- RAM: modest — roughly 100–200 MB. Your system layer was already lean; the
  big RAM users are your own dev/AI tools.
- Battery: small but real — fewer wakeup sources (geoclue, indexer crawls,
  double logging, redundant OOM pollers). Single-digit percent, measured at the end.
- Boot: potentially the biggest visible win (C3, re-measured under greetd).
- Processes: ~15–20 fewer.
- Updates/disk: B4 is the big one — fewer packages to download and patch forever.
