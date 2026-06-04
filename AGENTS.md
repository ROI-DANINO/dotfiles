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
