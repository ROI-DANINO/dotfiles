# Wallpaper Stack Sourcing Design

## Goal

Build a larger wallpaper stack that fits Roi's desktop brand palette and monitor shape.
The stack should feel coherent on the Niri desktop while still rotating through varied
subjects.

## Display Constraint

- Target monitor: 2880x1800 physical pixels.
- Required final aspect ratio: 16:10.
- Required final resolution: 3840x2400 or better.
- Preferred native source sizes: 3840x2400, 5120x3200, or larger 16:10.
- Near-match high-resolution images are allowed only when they can be cropped cleanly
  to 16:10 without harming the subject.

## Brand Palette

Candidate wallpapers should harmonize with the active desktop palette:

- Navy: `#1E3045`, `#2F4156`, `#081A2F`
- Teal / muted blue: `#567C8D`, `#9FB4C1`, `#C8D9E6`
- Cream: `#F0E7D5`, `#D8CBB7`
- Warm accents: `#E0B66C`, `#C9856F`, copper/rust tones

## Category Mix

The stack personality should be led by desert and weathered scrap imagery:

- 35% desert scenery
- 35% rusted scrap, old cars, weathered metal, patina, abandoned objects
- 20% wildlife / nature
- 10% sea life

Wildlife, nature, and sea life are supporting variety, not the main identity.

## Selection Rules

Accept images that:

- Feel desktop-friendly with calm space for Waybar, terminals, and lock screen UI.
- Have a clear subject without the subject filling the entire frame.
- Use muted, brand-compatible color grading.
- Preserve strong framing after a 16:10 crop when cropping is needed.
- Are real high-resolution images, not obvious low-resolution upscales.

Reject images that:

- Are dark, muddy, fog-heavy, or branch-heavy forest scenes.
- Look like generic bright stock nature.
- Use neon, harsh tropical saturation, or loud one-note color.
- Crop the subject awkwardly on a 16:10 display.
- Are below 3840x2400 after final crop.

## Sourcing Approach

Use exact 16:10 sources first. Search for `3840x2400`, `5120x3200`, and larger
16:10 image results before considering cropped near-matches.

If exact 16:10 choices are too limited, allow exceptional high-resolution images from
trusted photo sources and crop them to 16:10 locally.

## Output

Downloaded wallpapers should be placed in:

```text
wallpapers/Pictures/walpapers/
```

Filenames should be readable and source-aware, following the existing style where
possible.
