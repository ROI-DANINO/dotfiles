# GTK Brand Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the brand navy/cream/teal palette to GTK3/GTK4 apps (blueman, thunar, nm-applet) via a global `gtk.css` override stow module.

**Architecture:** Create a `gtk` stow module with `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` that redefine GTK's named color variables. Orchis-Dark is kept as the base theme; the CSS layer swaps its grey palette for brand navy values. Register the module in `stow.sh` so it deploys alongside all other dotfiles.

**Tech Stack:** GNU Stow, GTK3/GTK4 CSS (`@define-color`, widget selectors)

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Create | `gtk/.config/gtk-3.0/gtk.css` | Brand color overrides for GTK3 apps |
| Create | `gtk/.config/gtk-4.0/gtk.css` | Same overrides for GTK4 apps |
| Modify | `stow.sh` | Add `gtk` to PACKAGES array |
| Modify | `README.md` | Document the new stow module |
| Modify | `packages.md` | Note no new packages needed |

---

### Task 1: Create GTK3 CSS override

**Files:**
- Create: `gtk/.config/gtk-3.0/gtk.css`

- [ ] **Step 1: Create the directory structure**

```bash
mkdir -p gtk/.config/gtk-3.0
mkdir -p gtk/.config/gtk-4.0
```

- [ ] **Step 2: Write `gtk/.config/gtk-3.0/gtk.css`**

```css
/* Brand palette — layered on top of Orchis-Dark */

@define-color theme_bg_color           #2F4156;
@define-color theme_base_color         #1E3045;
@define-color theme_fg_color           #F0E7D5;
@define-color theme_selected_bg_color  #C8D9E6;
@define-color theme_selected_fg_color  #1E3045;
@define-color borders                  #567C8D;
@define-color unfocused_borders        #3a556a;
@define-color insensitive_bg_color     #263749;
@define-color insensitive_fg_color     #9FB4C1;
@define-color theme_tooltip_bg_color   #1E3045;
@define-color theme_tooltip_fg_color   #F0E7D5;

headerbar,
.titlebar {
  background-color: #1E3045;
  color: #F0E7D5;
}

.sidebar {
  background-color: #1E3045;
}

popover,
.popover {
  background-color: #2F4156;
  border: 1px solid #567C8D;
}
```

- [ ] **Step 3: Verify file created correctly**

```bash
cat gtk/.config/gtk-3.0/gtk.css
```

Expected: file prints the CSS above with no truncation.

---

### Task 2: Create GTK4 CSS override

**Files:**
- Create: `gtk/.config/gtk-4.0/gtk.css`

- [ ] **Step 1: Write `gtk/.config/gtk-4.0/gtk.css`**

```css
/* Brand palette — layered on top of Orchis-Dark (GTK4) */

@define-color window_bg_color          #2F4156;
@define-color window_fg_color          #F0E7D5;
@define-color view_bg_color            #1E3045;
@define-color view_fg_color            #F0E7D5;
@define-color accent_bg_color          #567C8D;
@define-color accent_fg_color          #F0E7D5;
@define-color accent_color             #C8D9E6;
@define-color headerbar_bg_color       #1E3045;
@define-color headerbar_fg_color       #F0E7D5;
@define-color sidebar_bg_color         #1E3045;
@define-color popover_bg_color         #2F4156;

/* GTK4 also checks these legacy names */
@define-color theme_bg_color           #2F4156;
@define-color theme_base_color         #1E3045;
@define-color theme_fg_color           #F0E7D5;
@define-color theme_selected_bg_color  #C8D9E6;
@define-color theme_selected_fg_color  #1E3045;
```

- [ ] **Step 2: Verify file created correctly**

```bash
cat gtk/.config/gtk-4.0/gtk.css
```

Expected: file prints the CSS above with no truncation.

---

### Task 3: Register module in stow.sh and deploy

**Files:**
- Modify: `stow.sh` — add `gtk` to PACKAGES array

- [ ] **Step 1: Add `gtk` to the PACKAGES array in `stow.sh`**

Find this block in `stow.sh`:

```bash
PACKAGES=(
  niri
  kitty
  waybar
  swaync
  zellij
  shell
  git
  scripts
  wallpapers
)
```

Change to:

```bash
PACKAGES=(
  niri
  kitty
  waybar
  swaync
  zellij
  shell
  git
  gtk
  scripts
  wallpapers
)
```

- [ ] **Step 2: Dry-run stow to confirm no conflicts**

```bash
./stow.sh --dry-run 2>&1 | grep gtk
```

Expected output contains something like:
```
LINK: .config/gtk-3.0/gtk.css => ../../dotfiles/gtk/.config/gtk-3.0/gtk.css
LINK: .config/gtk-4.0/gtk.css => ../../dotfiles/gtk/.config/gtk-4.0/gtk.css
```

If output shows `CONFLICT` instead, an existing `~/.config/gtk-3.0/gtk.css` or `~/.config/gtk-4.0/gtk.css` is present — remove it first:

```bash
rm -f ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css
```

Then re-run the dry-run step.

- [ ] **Step 3: Deploy**

```bash
./stow.sh 2>&1 | grep gtk
```

Expected:
```
  ✓ gtk
```

- [ ] **Step 4: Confirm symlinks exist**

```bash
ls -la ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css
```

Expected: both lines show `->` pointing into the dotfiles repo.

---

### Task 4: Visual verification

No automated test is possible for GTK color changes — verify visually by launching each app.

- [ ] **Step 1: Launch thunar and inspect**

```bash
thunar &
```

Expected: file manager window background is navy (`#2F4156`), not grey. Selected files highlight in sky blue (`#C8D9E6`).

- [ ] **Step 2: Launch blueman and inspect**

```bash
blueman-manager &
```

Expected: bluetooth manager window background is navy. Header bar is navy-deep (`#1E3045`).

- [ ] **Step 3: Check nm-applet connection dialog**

Click the nm-applet tray icon to open the connection dialog. Expected: window background is navy, not grey.

- [ ] **Step 4: Kill test instances**

```bash
pkill thunar; pkill blueman-manager
```

---

### Task 5: Update docs and commit

**Files:**
- Modify: `README.md` — add gtk stow module entry
- Modify: `packages.md` — note gtk.css, no new packages

- [ ] **Step 1: Add gtk module entry to README.md**

Find the stow modules table in `README.md` (near the section listing `niri`, `kitty`, `waybar`, etc.) and add a row:

```markdown
| `gtk` | `~/.config/gtk-{3,4}.0/gtk.css` | Brand palette override for GTK apps |
```

- [ ] **Step 2: Add note to packages.md**

Find the `## Network & Bluetooth` section in `packages.md` and add below it:

```markdown
## GTK Theme Override

No packages required. The `gtk` stow module deploys `~/.config/gtk-3.0/gtk.css`
and `~/.config/gtk-4.0/gtk.css` which layer brand navy/cream/teal colors on top
of the active Orchis-Dark GTK theme. Applies to: blueman, thunar, nm-applet, walker.
```

- [ ] **Step 3: Commit everything**

```bash
git add gtk/ stow.sh README.md packages.md
git commit -m "$(cat <<'EOF'
Apply brand palette to GTK apps via gtk.css override

Adds gtk stow module with gtk-3.0/gtk.css and gtk-4.0/gtk.css that redefine
GTK named color variables to brand navy/cream/teal. Covers blueman, thunar,
nm-applet, and walker without forking Orchis-Dark.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
