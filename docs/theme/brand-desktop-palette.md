# Brand Desktop Palette

Source spec: `docs/superpowers/specs/2026-05-31-brand-anchored-desktop-theme-design.md`

## Official Brand Colors

| Token | Hex | Use |
|---|---:|---|
| `brand-sky` | `#C8D9E6` | Focus, selected states, soft highlights |
| `brand-navy` | `#2F4156` | Main dark brand base |
| `brand-teal` | `#567C8D` | Borders, icons, secondary accents |
| `brand-cream` | `#F0E7D5` | Warm text/cards/soft surfaces |
| `brand-white` | `#FFFFFF` | Highest contrast on dark surfaces |

## Desktop Derived Colors

| Token | Hex | Use |
|---|---:|---|
| `navy-deep` | `#1E3045` | Terminal background and deeper panels |
| `navy-ink` | `#081A2F` | Deepest terminal black/shadow |
| `sky-muted` | `#9FB4C1` | Muted text on dark surfaces |
| `cream-muted` | `#D8CBB7` | Muted warm text |
| `success` | `#A8C9B0` | Healthy/charging/good |
| `warning` | `#E0B66C` | Warning only |
| `danger` | `#C9856F` | Critical/error/urgent |
| `selection` | `#C8D9E6` | Selection background on dark surfaces |

## Transparency Defaults

- Kitty: `background_opacity 0.86` (navy-deep background).
- Waybar: use translucent Navy/deep Navy surfaces.
- Dunst: opaque cards (brand-navy bg, teal frame) — transparency not used.
- swaylock: navy-ink background, brand-teal ring, brand-sky key-highlight.
- GTK overlay bars: use translucent Navy.

## Rules

- Brand colors stay exact when used as brand tokens.
- No gold as an accent.
- No neon/electric blue.
- Preserve readability over transparency when they conflict.
