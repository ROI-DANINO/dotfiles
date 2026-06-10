# CLAUDE.md

All repo context, conventions, and hard rules live in @AGENTS.md — read it before making changes.

Critical reminders (full versions in `docs/agent-reference/operational-protocols.md`):

- **No interactive sudo** — output the command, wait for the user to run it and reply "Done".
- **Dry-run every `dnf remove`** (`--assumeno` first) and read the removal list together.
- **Configs are live symlinks** (GNU Stow) — editing a repo file edits the running system.
