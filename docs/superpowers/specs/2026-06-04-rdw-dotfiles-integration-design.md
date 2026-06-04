# RDW → dotfiles integration — design (Phase 1: scaffold)

**Date:** 2026-06-04
**Status:** Approved — ready for implementation plan
**Owner:** Roi Danino

## Problem

The dotfiles repo has grown a real project-management need: a 19KB `AGENTS.md`, a
`README.md`, scattered `docs/superpowers/{specs,plans,handoffs}`, and an active
`.remember/` history — but no durable spine tying them together (no roadmap, no
phase state, no per-session checkpoint, no build log). The **RDW** workflow plugin
(`~/Desktop/Projects/workspace`, `plugin.json` name `rdw` v2.0.0) provides exactly
that spine: `/rdw-init`, `/rdw-start`, `/rdw-end`, riding on the **superpowers** and
**remember** plugins — both already installed and in use here.

Goal: stand up the RDW project-management + documentation layer on dotfiles,
**keeping the existing structure intact** and enhancing it, not replacing it.

## Constraints & decisions

Settled with the owner during brainstorming:

1. **Sequencing — scaffold first, slim AGENTS.md as Phase 2.** This pass is additive
   and low-risk. The AGENTS.md restructure (extracting protocols / keybind map /
   daemon architecture into reference docs, leaving a lean read-first index) is a
   bigger, riskier edit and becomes Phase 2 — driven by `/rdw-*` itself as the first
   real dogfood of the framework.
2. **Commands are project-local, not a plugin install.** Copy the command files into
   the repo's `.claude/commands/`; do not register a marketplace or vendor the plugin
   source into dotfiles. The RDW source stays in its own repo.
3. **docs-map points at existing paths.** Reference the existing
   `docs/superpowers/{specs,plans,handoffs}` rather than migrating to RDW's default
   `docs/specs` + `docs/plans`. The manifest is config; the one it names wins.
4. **AGENTS.md kept fully intact** in Phase 1 — only a small "Current phase" pointer
   appended. No existing content moved or rewritten.

## Design

### 1. Commands — project-local

Copy into `~/dotfiles/.claude/commands/`:

- `rdw-start.md`, `rdw-end.md` — verbatim (neither references `${CLAUDE_PLUGIN_ROOT}`).
- `rdw-init.md` — the only file using `${CLAUDE_PLUGIN_ROOT}/templates/`; repoint that
  reference at the source repo (`~/Desktop/Projects/workspace/templates/`). This only
  affects future fresh scaffolds; on dotfiles the manifest will already exist, so
  `/rdw-init` runs in harmless re-tune mode.

Tracking: `git add .claude/commands/`; keep `.claude/settings.local.json` and
`.claude/worktrees/` ignored.

### 2. Instance layer — scaffold (mirrors `/rdw-init` "existing project")

New **tracked** files, filled with dotfiles' real content (not template placeholders):

- `ROADMAP.md` — destination = a reproducible, brand-themed Niri desktop managed via
  GNU Stow with a self-documenting workflow. Phases reflect reality: shipped
  (bootstrap / theming / lockscreen) → **active: RDW workflow spine** → next: slim
  AGENTS.md.
- `PROGRESS.md` — actual done / in-progress / open questions.
- `journal/docs-map.md` — the customized manifest (see §4).
- `journal/ops/phase.md` — `phase: build`, `step: "land RDW scaffold + project-local commands"`.
- `journal/ops/tasks.md` — current-phase tasks.
- `journal/context/active.md` — resume context.
- `journal/log.md` — append-only session log.
- `journal/ops/sessions/` (dir), `journal/ops/archive/.gitkeep`, `journal/raw/_inbox/.gitkeep`.
- `blog/README.md` — build-log index (style guardrails from the RDW template).

`.remember/remember.md` already exists (gitignored runtime state) and is left to the
remember / `/rdw-end` mechanism.

### 3. AGENTS.md — minimal, non-destructive

All existing content untouched. Append one short `## Current phase` section pointing
to `journal/ops/phase.md`, and note that `journal/docs-map.md` governs source-of-truth.
The real slim-down is Phase 2.

### 4. docs-map — customized to real surfaces

Frontmatter: `profile: dev-project`, `root: journal`, `desks: []`, `blog: true`.

Source-of-truth table:

| File | Source of truth for |
|------|---------------------|
| AGENTS.md | Operational protocols, mission, current-phase pointer. Read first. |
| README.md | Human-facing overview / quick start. |
| ROADMAP.md | Destination, phases, exit criteria. |
| PROGRESS.md | What is done / in progress now; open questions. |
| journal/ops/phase.md | Machine-readable current phase state. |
| journal/ops/tasks.md | Tasks for the current phase only. |
| journal/context/active.md | Resume context for /rdw-start. |
| journal/ops/sessions/ | /rdw-end handoff files (history). |
| docs/superpowers/specs/ | Design specs / ADRs (existing path). |
| docs/superpowers/plans/ | Implementation plans (existing path). |
| docs/superpowers/handoffs/ | Session handoffs (existing path). |
| blog/ | First-person build log; the "why". |
| .remember/remember.md | Short handoff to the very next session. |

### 5. Git & stow hygiene

- `.gitignore`: add `.claude/settings.local.json`, `.claude/worktrees/` (commands stay
  tracked). `.remember/` + `.superpowers/` already ignored.
- `.stow-global-ignore`: add `journal`, `blog`, `\.claude`, `ROADMAP\.md`,
  `PROGRESS\.md` so they are never symlinked into `$HOME` (matches existing `docs` /
  `system` exclusions).
- Commit: `rdw-init: scaffold RDW onto dotfiles (project-local commands + instance)`.

## Verification

- `/rdw-start`, `/rdw-end`, `/rdw-init` appear as project commands in Claude Code.
- docs-map drift check: every file the manifest names exists on disk.
- `stow.sh` dry-run shows no new symlinks for `journal/`, `blog/`, or `.claude/`.

## Out of scope (Phase 2)

Slimming `AGENTS.md` by extracting protocols, keybind map, and daemon architecture
into reference docs that the lean AGENTS.md links to — driven through `/rdw-*` as the
first real use of the framework on dotfiles.
