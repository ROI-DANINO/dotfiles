# Lean AGENTS.md + reference docs — design

**Date:** 2026-06-04
**Status:** Approved — ready for owner spec review
**Owner:** Roi Danino

## Problem

`AGENTS.md` is currently the correct read-first file for this dotfiles repo, but it has
grown to about 400 lines. The file contains several different kinds of material:
always-on operational rules, repo orientation, keybind tables, daemon architecture,
package-removal history, machine notes, and removed-component history.

That makes the most important constraints harder for agents to keep in working
memory. The next phase should preserve every important rule while making the loaded
entrypoint smaller, more scannable, and closer to the lean project instructions used in
`Roi_Danino/CLAUDE.md` and `feather-browser/AGENTS.md`.

## Research notes

The current ecosystem guidance points in one direction:

- The `agents.md` project presents AGENTS.md as a predictable "README for agents" and
  shows a compact example focused on environment, test, and PR instructions:
  https://github.com/agentsmd/agents.md
- Claude Code's best-practices docs say project memory should stay short,
  human-readable, broadly applicable, and pruned when rules are no longer earning their
  place:
  https://code.claude.com/docs/en/best-practices
- GitHub Copilot's docs make the same split: always-on custom instructions are for
  simple broad rules; detailed or situational workflows belong in skills or other
  on-demand references:
  https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/agents/copilot-cli/comparing-cli-features
- The local examples reinforce the shape: `Roi_Danino/CLAUDE.md` is roughly 75 lines
  and `feather-browser/AGENTS.md` is roughly 104 lines, both acting as lean indexes
  with links to deeper project state.

## Decision

Use a **lean index + reference docs** structure.

`AGENTS.md` remains the first file agents read, but it should carry only information
that applies to almost every task:

1. Repo identity and purpose.
2. Critical non-negotiable rules.
3. Startup / RDW orientation flow.
4. Current phase pointer.
5. Compact repository map.
6. Links to reference docs for deeper context.

Detailed tables, history, and long explanations move into `docs/agent-reference/`.
This keeps the constraints versioned and discoverable without injecting all details
into every session by default.

## Alternatives considered

### Keep one large AGENTS.md, but prune prose

This would be the lowest-risk edit, but it leaves the core problem intact: unrelated
details still compete with the hard rules.

### Add nested AGENTS.md files under config packages

Nested instruction files are useful in large monorepos or services with genuinely
different local rules. This repo is small and highly integrated; package-specific
instruction files would add discovery complexity without much benefit.

### Recommended: lean index + reference docs

This is the best fit for the repo. It matches the local examples, preserves every
important fact, and gives agents a short operational contract plus clear paths for
deeper context.

## Target file structure

Create:

- `docs/agent-reference/README.md` — index for extracted agent reference docs.
- `docs/agent-reference/operational-protocols.md` — sudo handoff, live symlink
  awareness, stow conflict checks, package-removal safety, and secrets architecture.
- `docs/agent-reference/stow-architecture.md` — GNU Stow package layout and
  manual-only `system/` boundary.
- `docs/agent-reference/niri-keybinds.md` — full keybind map, locked binds, free binds,
  and startup app table.
- `docs/agent-reference/daemon-services.md` — Niri startup chain, elephant, wob,
  swayidle, lock-screen, and wallpaper rotation.
- `docs/agent-reference/power-management.md` — TLP battery threshold and Waybar battery
  behavior.
- `docs/agent-reference/package-safety-history.md` — removed components, package
  gotchas, and re-request guidance.
- `docs/agent-reference/machine-notes.md` — display, keyboard, Java, timezone, npm, and
  other machine-specific notes.

Modify:

- `AGENTS.md` — rewrite as a lean read-first index that links to the reference docs.
- `journal/docs-map.md` — register `docs/agent-reference/` as the source of truth for
  detailed agent reference material.
- `PROGRESS.md` — mark Phase 4 scaffold as done and Phase 5 as in progress.
- `journal/ops/tasks.md` — update Phase 5 tasks as they are completed.
- `journal/context/active.md` — update resume context after the implementation.
- `journal/ops/phase.md` — keep phase state truthful after the implementation.

## AGENTS.md shape

The rewritten `AGENTS.md` should target roughly 100-140 lines. It should not try to be
minimal at the expense of safety; the critical rules must remain visible.

Proposed sections:

1. `# AGENTS.md — AI Context for dotfiles`
2. `## Project Identity`
3. `## Critical Rules`
4. `## Startup Flow`
5. `## Current Phase`
6. `## Repository Map`
7. `## Reference Docs`
8. `## Locked Decisions`

The `Critical Rules` section should keep short versions of the rules that agents must
obey without needing another file:

- No interactive `sudo`; output exact commands and wait for confirmation.
- Treat repo edits as live config edits because files are stowed into `$HOME`.
- Run `./stow.sh --dry-run` before `stow.sh` or `install.sh`.
- Never provide real `sudo dnf remove` or `autoremove` commands before an
  `--assumeno` dry-run and review.
- Never put secrets in tracked files.
- Check the keybind map before changing or removing Niri binds.
- Never automate `system/`; it is manual reference only.
- Ask before adding packages to `stow.sh`.

## Preservation requirements

No information should be lost. Every current section in `AGENTS.md` must land in one of
three places:

1. The new lean `AGENTS.md`.
2. One of the `docs/agent-reference/*.md` files.
3. Existing source-of-truth docs if the information is already authoritative elsewhere.

Protocol numbering should be normalized in the extracted docs. The current file lists
Protocol 5 before Protocol 4; the rewrite should preserve content while presenting the
protocols in logical order.

## Verification

Run these checks before calling the implementation complete:

1. `wc -l AGENTS.md docs/agent-reference/*.md`
   - Expected: `AGENTS.md` is materially smaller than the current 400 lines.
2. Docs-map existence check for every path named in `journal/docs-map.md`.
   - Expected: every path exists.
3. `rg` checks for critical terms across `AGENTS.md docs/agent-reference`:
   - `sudo`
   - `dnf remove`
   - `Thunar`
   - `zenity`
   - `Mod+Slash`
   - `Mod+Space`
   - `elephant`
   - `hyprlock`
   - `STOP_CHARGE_THRESH_BAT0`
   - `auto-cpufreq`
4. `./stow.sh --dry-run`
   - Expected: no new stow conflicts or unintended symlinks from docs/journal changes.
5. `git diff --check`
   - Expected: no whitespace errors.

## Out of scope

- Changing Niri keybinds, startup apps, packages, shell aliases, services, or live
  desktop behavior.
- Adding new stow packages.
- Changing `install.sh` behavior.
- Moving `system/` into automation.
- Rewriting `README.md` beyond any small consistency note that becomes necessary.
