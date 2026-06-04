# Roadmap

> Destination, phases, milestones, exit criteria. Authoritative for *where we're going*.

## Destination
A reproducible, brand-themed Niri desktop on Fedora — every config symlinked from this
repo via GNU Stow, installable from a clean machine with `install.sh`, and self-documenting
through the RDW workflow spine (AGENTS.md → journal → blog).

## Phases
- [x] Phase 1: **Bootstrap** — stow layout, install.sh, core Niri/waybar/kitty/shell configs.
- [x] Phase 2: **Brand theming** — Navy/cream/terracotta palette across kitty, gtk, dunst,
      waybar, walker, wob, zed.
- [x] Phase 3: **Lockscreen** — swaylock → hyprlock (instant lock, OLED gradient backgrounds).
- [x] Phase 4: **RDW workflow spine** — project-local /rdw-* commands + journal/blog/roadmap
      scaffold over the installed superpowers + remember plugins.
      Exit: scaffold committed; docs-map drift-clean; commands load.
- [x] Phase 5: **Slim AGENTS.md** — extract protocols / keybind map / daemon architecture into
      reference docs; leave AGENTS.md a lean read-first index that links to them.
      Exit: AGENTS.md is an index; reference docs registered in docs-map; nothing lost.
      Delivered in PR #1 (with Phase 4).
