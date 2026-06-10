# Machine Efficiency Audit — Design

**Date:** 2026-06-10
**Status:** Approved approach A (measure-first phased audit)

## Goal

Measurably reduce battery drain, RAM, CPU, and running-process count on this
Fedora 43 + niri laptop, with before/after evidence for every change. The owner
wants to *know* the machine is efficient, not assume it. No animation or UX
regressions — this is about removing waste, not degrading the experience.

## Owner constraints (from brainstorming)

- **Keep gnome-shell** as the emergency session (reachable via tuigreet since
  the greetd migration). Trim GNOME *apps* and background services only.
- **Keep GNOME Boxes** and its virt stack (qemu/libvirt) — actively wanted.
- **Keep gnome-keyring** — system-wide secrets, not GNOME-specific (see
  package-safety-history.md).
- **iPhone owner** — keep gvfs AFC monitor and MTP/gphoto2 USB support.
- **Keep hermes-gateway and codex-update-manager** user services.
- **Investigate mcp-duckduckgo** (:18800) — check who connects before any verdict.
- **No printing/scanning** — cups/sane/avahi are removal candidates.
- **Location**: darkman is the only real consumer → switch darkman to fixed
  coordinates, then geoclue + geoclue-demo-agent become disable candidates.
- **GNOME Online Accounts / Evolution Data Server**: owner does not knowingly
  use them → removal candidates (kills OnlineAccounts, Identity, goa-volume-monitor
  services).
- **Tool preference**: owner dislikes raw CLI tools — any replacement app
  suggested must be at minimum a nice TUI, preferably a light, good-looking GUI.
- **TLP owns power policy.** Measurement uses powertop in report mode ONLY —
  never `powertop --auto-tune` (conflicts with TLP). Do not suggest
  auto-cpufreq or tuned (removed 2026-05-30, see power-management.md).

## Process protocols (binding)

- All sudo commands are handed to the owner to run; agent waits for "Done"
  (operational-protocols.md PROTOCOL 1).
- Every `dnf remove` is dry-run first with `--assumeno`; the full Removing list
  is read against install.sh, keybinds, and the startup chain before the real
  command is issued (PROTOCOL 5).
- Changes are reversible and logged: prefer `systemctl disable` over mask,
  record `dnf history` IDs, write revert commands into the findings table.
- A phase must survive a reboot before the next phase starts.

## Phases

### Phase 0 — Baseline (read-only)

Capture into `docs/superpowers/specs/audit-data/` (gitignored if large):
- `powertop --html` report on battery (drains + wakeups per process)
- `ps_mem` (or smem) snapshot — true RAM per process
- `systemd-analyze blame` + `critical-chain` — boot cost
- Inventory: enabled system units, enabled user units, autostart .desktop
  files, DE-related package list
- Idle CPU wakeup sample

### Phase 1 — Findings report

One table, one row per candidate: **what it is** (plain words), **measured
cost**, **why remove/disable**, **what is lost**, **revert command**. Grouped:
1. Safe for everyone
2. Safe for this owner's profile (per constraints above)
3. Judgment calls — owner decides per row

Rows that cost ~nothing are explicitly marked "keep — not worth the churn".
Known candidates going in: geoclue + demo agent, SELinux troubleshooter applet,
abrt Problem Reporting applet, GOA/EDS stack, GNOME apps (Maps, Contacts,
Calendar, Clocks, Connections, remote-desktop, initial-setup, classic-session;
owner ticks per app — Calculator/Clocks may stay), cups/sane/avahi, mcp-duckduckgo
(pending connection check), PackageKit refresh timers, ModemManager (if no WWAN),
pcscd (if no smartcard use), duplicate portal backends (gnome + gtk — verify which
one the file chooser actually uses before touching).

### Phase 2 — Apply, in batches

Order: user-session autostarts → GNOME app/package trim → system services →
boot chain. Each batch: apply approved rows → verify session functionality
(file chooser, bluetooth, audio, lock screen, iPhone mount) → reboot → confirm.

### Phase 3 — Re-measure + final report

Repeat Phase 0 measurements, diff against baseline. Final report committed to
the repo: per-item savings, totals (idle watts, MB RAM, boot seconds, process
count), and a "fresh machine" checklist so install.sh-based setups start lean.
Update package-safety-history.md with everything removed.

## Out of scope

- Animation/compositor tuning (explicitly excluded by owner)
- TLP/charge-threshold changes (owned, settled)
- system/ configs (earlyoom, zram, journald, sysctl) — already tuned; only
  flagged if Phase 0 data shows a problem
- Multi-day battery-discharge logging (approach C) — optional follow-up if
  Phase 3 numbers look wrong
