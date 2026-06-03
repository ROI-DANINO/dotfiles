## Active — RDW scaffold checkpointed

**Resume here:** RDW Phase 1 is scaffolded and pushed on branch `rdw-dotfiles-scaffold`.
Spec: docs/superpowers/specs/2026-06-04-rdw-dotfiles-integration-design.md.

## Next
- [ ] Open/review the PR for `rdw-dotfiles-scaffold`.
- [ ] Start Phase 5 with `/rdw-start`: slim `AGENTS.md` into a lean index and extract the
      large protocol/keybind/daemon sections into reference docs registered in
      `journal/docs-map.md`.

## Done
- Design brainstormed and approved; spec written and committed.
- Project-local `/rdw-start`, `/rdw-end`, and `/rdw-init` commands copied into
  `.claude/commands/`.
- RDW instance scaffold created: `ROADMAP.md`, `PROGRESS.md`, `journal/`, and `blog/`.
- Current-phase pointer appended to `AGENTS.md`.
- Stow hygiene updated for `journal`, `blog`, `.claude`, `ROADMAP.md`, and `PROGRESS.md`.
- Verification passed: docs-map paths exist, `CLAUDE_PLUGIN_ROOT` count is `0`, and
  `./stow.sh --dry-run` exits cleanly.
- Branch `rdw-dotfiles-scaffold` pushed to `origin`.
