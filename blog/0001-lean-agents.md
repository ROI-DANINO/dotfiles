# 0001 — The 400-line file my agents kept ignoring

**Date:** 2026-06-04
**Milestone:** Phase 5 — slim `AGENTS.md` into a lean read-first index

My `AGENTS.md` had become a 400-line monster. It started as the one file an AI agent
should read before touching my dotfiles — the rules of the house. But every time I
learned a new lesson the hard way (don't `dnf remove` Thunar, don't bind `Mod+Space`,
hyprlock replaced swaylock), I bolted another section onto it. Protocols, the full Niri
keybind table, daemon architecture, package-removal post-mortems, machine notes, a
changelog of everything I'd ever deleted.

Here's the thing about a 400-line instruction file: the agent reads all of it, and so
none of it stands out. The eight rules that actually prevent disasters were drowning in
nine sections of reference trivia. The most important constraints had the least room to
breathe.

So this phase I did the boring, correct thing: I split it. `AGENTS.md` is now 79 lines —
identity, the critical rules, the startup flow, a repo map, and links. Everything else
moved into eight focused docs under `docs/agent-reference/`, pulled in only when a task
actually touches that area. The contract an agent must hold in working memory shrank by
80%; nothing was lost.

The discipline that made this safe wasn't the writing — it was the verification. Before
calling it done I grepped every critical term (`sudo`, `dnf remove`, `Thunar`,
`STOP_CHARGE_THRESH_BAT0`...) across the new files to prove none had evaporated in the
move, confirmed every path in my docs-map still existed, and ran a stow dry-run to make
sure I hadn't accidentally turned a doc folder into a live symlink. Evidence before
assertions. Then, and only then, the PR.

The meta-joke: I did all of this *through* the workflow spine I'd just scaffolded — the
journal, the roadmap, the phase state. Phase 5 was the first real dogfood of the system
that Phase 4 built. It held.

🔗 My AI coding agent kept ignoring the most important rules in my repo. The fix wasn't
better rules — it was deleting 80% of the file they lived in. Here's why a 79-line
instruction file beats a 400-line one every time. 👇
