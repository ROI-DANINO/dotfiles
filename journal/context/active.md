## Active — security hardening + wallpaper swap done (mix rebalance pending)

**Resume here:** `layout-fix-robustness` merged to `master` and the branch deleted
(local+remote). 2026-06-10 hardening session shipped and pushed; repo and live machine
audited in sync. Only the wallpaper mix rebalance and key rotation remain.

## Next
- [ ] Rebalance wallpaper mix — more rust/scrap (35% target, now 17%), fewer sea/tropical;
  review bright parrot/tropical keepers against brand palette.
- [ ] Rotate the exposed Gemini API key (user action).

## Done
- Full repo + commit audit; live-machine audit (stow links, daemons, packages in sync).
- Hardcoded GEMINI_API_KEY found in uncommitted shell/.zshrc — moved to ~/.secrets
  (never committed; rotation still needed).
- Pre-commit secrets guard tracked at `githooks/pre-commit`, wired via `core.hooksPath`
  in install.sh.
- layout-fix lock moved /tmp → XDG_RUNTIME_DIR (`97b071d`); selftest 17/17.
- Wallpaper stack swapped (`e2ce027`): 41 out, 27 in, 36 final, all 3840x2400 16:10;
  mix: desert 36%, wildlife 22%, sea/tropical 25%, rust/scrap 17%.
- `record` alias + wf-recorder registered in packages.md/install.sh (`e77fb3a`).
- All pushed to origin/master; merged branch deleted.
- /rdw-next context-bridge command ported from feather-browser.
