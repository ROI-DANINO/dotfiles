## Active — layout-fix redesign complete (branch ready to merge)

**Resume here:** `layout-fix-robustness` branch has all four code tasks committed and
smoke-tested. Selftest 17/17 green. Branch is clean and ready to merge to `master`.

## Next
- [ ] Merge `layout-fix-robustness` to `master` (PR or direct merge; branch has 10 commits
  including the spec, plan, and 4 implementation commits).

## Done
- Task 1 (`e97e1b7`): single-instance flock lock.
- Task 2 (`a887b72`): timeouts on every external call.
- Task 3 (`4eda2c8`): always-backspace terminal replace, removed screen-scrape + dbg().
- Task 4 (`1c2e43d`): reverted kitty remote control.
- Task 5: selftest green, smoke test passed, niri-keybinds.md unchanged.
