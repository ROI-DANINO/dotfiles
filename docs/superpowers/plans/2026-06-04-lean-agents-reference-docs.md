# Lean AGENTS Reference Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 400-line root `AGENTS.md` with a lean read-first index and move detailed agent guidance into `docs/agent-reference/` without losing operational constraints.

**Architecture:** Keep `AGENTS.md` as the always-loaded operating contract. Move long tables, history, and detailed architecture notes into focused reference documents registered in `journal/docs-map.md`.

**Tech Stack:** Markdown, RDW journal files, GNU Stow dry-run verification, ripgrep.

---

## File Structure

- Create: `docs/agent-reference/README.md`
  - Index for the extracted reference docs.
- Create: `docs/agent-reference/operational-protocols.md`
  - Full sudo handoff, live symlink, stow conflict, secrets, and package-removal safety rules.
- Create: `docs/agent-reference/stow-architecture.md`
  - GNU Stow repository architecture and active package table.
- Create: `docs/agent-reference/niri-keybinds.md`
  - Full Niri keybind map, free binds, startup app table, and locked bind notes.
- Create: `docs/agent-reference/daemon-services.md`
  - Niri startup chain, elephant, wob-daemon, swayidle, hyprlock lock-screen flow, wallpaper rotation.
- Create: `docs/agent-reference/power-management.md`
  - TLP threshold, Waybar battery behavior, and auto-cpufreq replacement note.
- Create: `docs/agent-reference/package-safety-history.md`
  - Package removal gotchas and removed/archived component history.
- Create: `docs/agent-reference/machine-notes.md`
  - Machine-specific display, keyboard, Java, timezone, and npm notes.
- Modify: `AGENTS.md`
  - Rewrite as the lean read-first index.
- Modify: `journal/docs-map.md`
  - Add `docs/agent-reference/` as source of truth for detailed agent reference material and narrow `AGENTS.md` to the read-first operating contract.
- Modify: `PROGRESS.md`
  - Mark Phase 4 RDW scaffold done and Phase 5 lean AGENTS work in progress/done according to implementation state.
- Modify: `journal/ops/tasks.md`
  - Check off Phase 5 tasks as implementation progresses.
- Modify: `journal/context/active.md`
  - Update resume context after implementation.
- Modify: `journal/ops/phase.md`
  - Update `step`, `next`, and `note` to match the completed Phase 5 checkpoint.

---

### Task 1: Create Extracted Reference Docs

**Files:**
- Create: `docs/agent-reference/README.md`
- Create: `docs/agent-reference/operational-protocols.md`
- Create: `docs/agent-reference/stow-architecture.md`
- Create: `docs/agent-reference/niri-keybinds.md`
- Create: `docs/agent-reference/daemon-services.md`
- Create: `docs/agent-reference/power-management.md`
- Create: `docs/agent-reference/package-safety-history.md`
- Create: `docs/agent-reference/machine-notes.md`

- [ ] **Step 1: Create `docs/agent-reference/README.md`**

Use `apply_patch` to add an index with these exact links:

```markdown
# Agent Reference

Detailed reference material for agents working in this dotfiles repo. Root
`AGENTS.md` stays intentionally lean; use these files when a task touches the
relevant area.

## Files

- `operational-protocols.md` — sudo handoff, live symlink awareness, stow checks,
  package-removal safety, and secrets rules.
- `stow-architecture.md` — GNU Stow package layout and manual-only boundaries.
- `niri-keybinds.md` — full Niri keybind map, free binds, startup apps, and locked
  decisions.
- `daemon-services.md` — Niri startup chain, elephant, wob-daemon, swayidle,
  hyprlock, and wallpaper rotation.
- `power-management.md` — TLP battery threshold and battery indicator behavior.
- `package-safety-history.md` — package-removal gotchas and removed-component history.
- `machine-notes.md` — machine-specific hardware, keyboard, Java, timezone, and PATH
  notes.
```

- [ ] **Step 2: Create `operational-protocols.md`**

Move the full contents of current `AGENTS.md` sections:

- `## Critical Rules`
- `## **Operational Protocols & Constraints**`

Preserve all command examples exactly. Normalize protocol order to:

1. Sudo Handoff
2. Live Symlink Awareness
3. Stow Conflict Check
4. Secrets Architecture
5. Package Removal Safety

Keep the package removal gotcha bullets in this file as immediate safety context. Also
copy the same gotcha list into `package-safety-history.md` in Task 1 Step 7.

- [ ] **Step 3: Create `stow-architecture.md`**

Move the full current `## Repository Architecture (GNU Stow)` section into this file.
Keep the active package table unchanged and preserve the `system/` manual-only warning.

- [ ] **Step 4: Create `niri-keybinds.md`**

Move these current sections into this file:

- `## Philosophy`
- `## Niri Keybind Map`
- `## Startup Apps (niri spawn-at-startup)`
- `## Locked / Do Not Change`

Keep the keybind table unchanged. Add this note at the top:

```markdown
Read this before changing any Niri bind. Preserve both arrow and hjkl bindings.
```

- [ ] **Step 5: Create `daemon-services.md`**

Move the full current `## Daemon & Service Architecture` section into this file.
Keep the Niri process tree, elephant systemd service example, wob-daemon note,
swayidle pipeline, and wallpaper-rotate behavior unchanged.

- [ ] **Step 6: Create `power-management.md`**

Move the full current `## Power Management` section into this file. Preserve:

- `STOP_CHARGE_THRESH_BAT0=85`
- `/sys/class/power_supply/BAT0/charge_control_end_threshold`
- The instruction not to raise the 85% cap.
- The instruction not to suggest reinstalling `auto-cpufreq`.

- [ ] **Step 7: Create `package-safety-history.md`**

Move the full current `## What Was Removed` section into this file. Also include a
top section named `## Package Removal Gotchas` containing the gotcha bullets from
Package Removal Safety:

- `Thunar`
- `zenity`
- `swayidle`, `swaync`, `swaybg`
- `hyprlock`
- `swaylock`
- `gnome-keyring`, `gnome-keyring-pam`

- [ ] **Step 8: Create `machine-notes.md`**

Move the full current `## Machine-Specific Notes` section into this file.

- [ ] **Step 9: Review extraction coverage**

Run:

```bash
rg -n "Sudo Handoff|Live Symlink|Package Removal Safety|Secrets Architecture|Repository Architecture|Daemon & Service Architecture|Niri Keybind Map|Power Management|What Was Removed|Machine-Specific Notes" AGENTS.md docs/agent-reference
```

Expected: every phrase appears in either `AGENTS.md` or `docs/agent-reference/*`.

- [ ] **Step 10: Commit extracted docs**

```bash
git add docs/agent-reference
git commit -m "docs: extract detailed agent reference"
```

Expected: commit succeeds with only `docs/agent-reference/*` added.

---

### Task 2: Rewrite Root AGENTS.md As Lean Index

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Replace `AGENTS.md` with lean structure**

Use `apply_patch` to replace the file with these sections:

```markdown
# AGENTS.md — AI Context for dotfiles

Read this file before making any changes to this repo.

## Project Identity

- Owner: Roi Danino
- Machine: Fedora 43, Niri compositor
- Purpose: reproducible, brand-themed Niri desktop dotfiles managed by GNU Stow.
- Last major overhaul: 2026-05-30

## Critical Rules

- Do not run interactive `sudo`. Output exact commands in a code block and wait for the
  user to confirm they ran them.
- Treat edits as live config changes. Files in this repo are symlinked into `$HOME`
  through GNU Stow.
- Before `stow.sh` or `install.sh`, run `./stow.sh --dry-run` and inspect conflicts.
- Never provide a real `sudo dnf remove` or `sudo dnf autoremove` command before a
  `--assumeno` dry-run and review of the full removal list.
- Never put secrets in tracked files. Use `~/.secrets`, `~/.gitconfig.local`, or
  project-local untracked `.env` files.
- Never change or remove a Niri keybind without checking the keybind map first.
- Preserve both arrow and hjkl navigation binds in Niri.
- Never automate `system/`; it is manual-only reference.
- Ask before adding new packages to `stow.sh`.

## Startup Flow

1. Read this file.
2. Run `/rdw-start` or read `.claude/commands/rdw-start.md` and follow it manually.
3. Use `journal/docs-map.md` to resolve source-of-truth conflicts.
4. Read the specific reference docs needed for the task before editing live configs.

## Current Phase

This repo is managed with the RDW workflow spine:

- Phase state: `journal/ops/phase.md`
- Current tasks: `journal/ops/tasks.md`
- Resume context: `journal/context/active.md`
- Source-of-truth map: `journal/docs-map.md`

## Repository Map

- `install.sh` — idempotent one-shot package/service/stow setup.
- `stow.sh` — GNU Stow deploy only.
- `packages.md` — manual package reference.
- `niri/`, `waybar/`, `dunst/`, `hyprlock/`, `kitty/`, `shell/`, `git/`, `gtk/`,
  `wob/`, `walker/`, `zed/`, `scripts/`, `wallpapers/` — active stow packages.
- `system/` — manual-only system config reference; never stowed or automated.
- `archived/` — archived modules kept for possible manual restoration.
- `docs/agent-reference/` — detailed agent reference extracted from the old AGENTS.md.
- `journal/` — RDW phase state, tasks, sessions, and logs.

## Reference Docs

- `docs/agent-reference/operational-protocols.md` — full operational protocols,
  sudo handoff, stow safety, secrets, and package-removal safety.
- `docs/agent-reference/stow-architecture.md` — active stow packages and targets.
- `docs/agent-reference/niri-keybinds.md` — full keybind map, startup apps, and locked
  decisions.
- `docs/agent-reference/daemon-services.md` — Niri startup chain and user daemons.
- `docs/agent-reference/power-management.md` — TLP threshold and battery indicator.
- `docs/agent-reference/package-safety-history.md` — removed components and package
  gotchas.
- `docs/agent-reference/machine-notes.md` — machine-specific notes.

## Locked Decisions

- `Mod+Slash` launches walker.
- `Mod+T` launches kitty.
- `Mod+Space` is the keyboard layout toggle through XKB; do not bind it in Niri.
- `shell/zshrc` plugins stay limited to `zsh-autosuggestions` and
  `zsh-syntax-highlighting`.
- `zellij` remains archived because it breaks AI-agent CLI rendering.
- `hyprlock` is the active lock screen; `swaylock` is decommissioned.
- `alias claude='claude --dangerously-skip-permissions'` is intentional for this
  personal machine.
```

- [ ] **Step 2: Check line count**

Run:

```bash
wc -l AGENTS.md
```

Expected: line count is between 80 and 150.

- [ ] **Step 3: Commit lean AGENTS rewrite**

```bash
git add AGENTS.md
git commit -m "docs: slim AGENTS into read-first index"
```

Expected: commit succeeds with only `AGENTS.md` modified.

---

### Task 3: Update RDW Source-of-Truth State

**Files:**
- Modify: `journal/docs-map.md`
- Modify: `PROGRESS.md`
- Modify: `journal/ops/tasks.md`
- Modify: `journal/context/active.md`
- Modify: `journal/ops/phase.md`

- [ ] **Step 1: Update `journal/docs-map.md`**

Change the `AGENTS.md` row to:

```markdown
| AGENTS.md | Lean read-first operating contract for agents. |
```

Add this row after `docs/superpowers/handoffs/`:

```markdown
| docs/agent-reference/ | Detailed agent reference: protocols, stow architecture, keybinds, daemons, package history, machine notes. |
```

- [ ] **Step 2: Update `PROGRESS.md`**

Set `## Done` to include:

```markdown
- Phase 4 RDW workflow spine scaffolded and pushed on `rdw-dotfiles-scaffold`.
- Phase 5 AGENTS.md slimming design and plan written.
```

Set `## In progress` to:

```markdown
- Phase 5 — slim `AGENTS.md` into a lean read-first index and extract detailed agent
  reference docs under `docs/agent-reference/`.
```

Set `## Open questions` to:

```markdown
- <none right now>
```

- [ ] **Step 3: Update `journal/ops/tasks.md`**

Replace the Active section with:

```markdown
## Active
- [x] Open/review the PR for `rdw-dotfiles-scaffold`.
- [x] Research lean AGENTS.md / CLAUDE.md guidance and local examples.
- [x] Write and commit Phase 5 design spec.
- [x] Write and commit Phase 5 implementation plan.
- [x] Extract detailed agent reference docs.
- [x] Rewrite `AGENTS.md` as a lean read-first index.
- [x] Register `docs/agent-reference/` in `journal/docs-map.md`.
- [ ] Verify docs-map drift, preservation terms, stow dry-run, and whitespace.
- [ ] Commit Phase 5 AGENTS.md reference split.
```

- [ ] **Step 4: Update `journal/context/active.md`**

Replace the file with:

```markdown
## Active — Phase 5 AGENTS reference split

**Resume here:** Phase 5 is implementing the approved lean `AGENTS.md` +
`docs/agent-reference/` split.

Spec: `docs/superpowers/specs/2026-06-04-lean-agents-reference-docs-design.md`.
Plan: `docs/superpowers/plans/2026-06-04-lean-agents-reference-docs.md`.

## Next
- [ ] Run preservation and drift verification.
- [ ] Commit the Phase 5 docs split.

## Done
- Phase 4 RDW scaffold committed and pushed on branch `rdw-dotfiles-scaffold`.
- Lean AGENTS design researched, approved, written, and committed.
- Phase 5 implementation plan written.
- Detailed reference docs extracted under `docs/agent-reference/`.
- Root `AGENTS.md` rewritten as a lean read-first index.
```

- [ ] **Step 5: Update `journal/ops/phase.md`**

Set these frontmatter values:

```yaml
phase: build
sub_phase: null
plan: docs/superpowers/plans/2026-06-04-lean-agents-reference-docs.md
spec: docs/superpowers/specs/2026-06-04-lean-agents-reference-docs-design.md
step: "verify Phase 5 AGENTS reference split"
prior_phase: null
detour: []
blocking: null
next: "Run drift/preservation/stow verification, then commit Phase 5 docs split."
note: "Phase 5 AGENTS.md lean-index split implemented; verification pending."
```

Preserve the existing `sessions:` list.

- [ ] **Step 6: Commit RDW state updates**

```bash
git add journal/docs-map.md PROGRESS.md journal/ops/tasks.md journal/context/active.md journal/ops/phase.md
git commit -m "docs: update RDW state for AGENTS split"
```

Expected: commit succeeds with only RDW docs/state files modified.

---

### Task 4: Verify Preservation And Stow Safety

**Files:**
- Read: `AGENTS.md`
- Read: `docs/agent-reference/*.md`
- Read: `journal/docs-map.md`

- [ ] **Step 1: Check final line counts**

Run:

```bash
wc -l AGENTS.md docs/agent-reference/*.md
```

Expected: `AGENTS.md` is materially smaller than the original 400 lines and all
reference docs are non-empty.

- [ ] **Step 2: Check critical term preservation**

Run:

```bash
rg -n "sudo|dnf remove|Thunar|zenity|Mod\\+Slash|Mod\\+Space|elephant|hyprlock|STOP_CHARGE_THRESH_BAT0|auto-cpufreq" AGENTS.md docs/agent-reference
```

Expected: every term appears at least once in either `AGENTS.md` or
`docs/agent-reference`.

- [ ] **Step 3: Check docs-map paths**

Run:

```bash
for p in AGENTS.md README.md ROADMAP.md PROGRESS.md journal/ops/phase.md journal/ops/tasks.md journal/context/active.md journal/ops/sessions docs/superpowers/specs docs/superpowers/plans docs/superpowers/handoffs docs/agent-reference blog .remember/remember.md; do if [ -e "$p" ]; then printf 'OK %s\n' "$p"; else printf 'MISSING %s\n' "$p"; fi; done
```

Expected: every line begins with `OK`.

- [ ] **Step 4: Run stow dry-run**

Run:

```bash
./stow.sh --dry-run
```

Expected: command exits `0`; no conflicts are reported.

- [ ] **Step 5: Check whitespace**

Run:

```bash
git diff --check
```

Expected: no output and exit code `0`.

- [ ] **Step 6: Commit verification status if needed**

If Task 4 reveals needed doc fixes, apply them and amend the relevant commit or create:

```bash
git add AGENTS.md docs/agent-reference journal/docs-map.md PROGRESS.md journal/ops/tasks.md journal/context/active.md journal/ops/phase.md
git commit -m "docs: verify AGENTS reference split"
```

Expected: only documentation/state fixes are included.

---

### Task 5: Final Review Checkpoint

**Files:**
- Read: `git status --short --branch`
- Read: `git log --oneline -5`

- [ ] **Step 1: Inspect final git state**

Run:

```bash
git status --short --branch
git log --oneline -5
```

Expected: worktree is clean and recent commits show the spec, plan, extraction, lean
index rewrite, and RDW state updates.

- [ ] **Step 2: Report completion**

Report:

- New `AGENTS.md` line count.
- List of created `docs/agent-reference/` files.
- Verification commands run and outcomes.
- Current branch/ahead status.

