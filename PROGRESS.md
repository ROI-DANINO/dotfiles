# Progress

> What is done / in progress *now*, and open questions. Authoritative for current state.

## Done
- Bootstrap, brand theming, and hyprlock lockscreen migration shipped to master.
- superpowers + remember plugins installed and in active use (.superpowers/, .remember/).
- Phase 4 RDW workflow spine scaffolded on `rdw-dotfiles-scaffold`.
- Phase 5 AGENTS.md slimmed to a lean read-first index; detail extracted into
  `docs/agent-reference/` (8 docs). Verification passed; docs reconciled.
- PR #1 (`rdw-dotfiles-scaffold` → `master`) covering Phases 4 + 5 merged 2026-06-04.
- layout-fix robustness redesign merged to master (PR-less direct merge, June 4-10).
- Security hardening session 2026-06-10: Gemini key moved out of tracked file to
  ~/.secrets, pre-commit secrets guard in `githooks/` with core.hooksPath,
  layout-fix lock moved to XDG_RUNTIME_DIR.
- Wallpaper stack swapped: 36 curated 16:10 3840x2400 images, committed + pushed.
- /rdw-next context-bridge command ported from feather-browser.

## In progress
- Wallpaper mix rebalance pending (rust/scrap 17% vs 35% target).

## Open questions
- <none right now>
