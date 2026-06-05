# Wallpaper Stack Sourcing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Source and install a larger 16:10 wallpaper stack that fits Roi's brand colors and preferred subject mix.

**Architecture:** Treat wallpaper sourcing as a three-stage pipeline: find candidates, validate visual/technical fit, then install only verified files into the stowed wallpaper package. Keep all accepted files at 16:10 and 3840x2400 or better.

**Tech Stack:** Web search, ImageMagick `identify`/`convert`, `curl`, GNU Stow-managed wallpaper directory.

---

## File Structure

- Modify: `wallpapers/Pictures/walpapers/`
  - Add accepted wallpapers.
  - Keep only final files that are 16:10 and at least 3840x2400.
- Reference: `docs/superpowers/specs/2026-06-05-wallpaper-stack-sourcing-design.md`
  - Defines palette, category mix, accept rules, and reject rules.

## Task 1: Find Candidate Sources

- [ ] Search exact 16:10 candidates first:
  - Desert scenery: `3840x2400 desert wallpaper`, `5120x3200 desert landscape wallpaper`
  - Rusted scrap/cars: `3840x2400 rusted car wallpaper`, `5120x3200 abandoned car desert wallpaper`, `weathered metal wallpaper 3840x2400`
  - Wildlife/nature: `3840x2400 wildlife wallpaper muted`, `3840x2400 fox deer meadow wallpaper`
  - Sea life: `3840x2400 sea turtle wallpaper`, `3840x2400 seal ocean wallpaper`
- [ ] Prefer sources that expose original image dimensions and direct download options.
- [ ] Record candidate links before downloading.

## Task 2: Filter Candidates

- [ ] Keep candidates that match the approved category mix:
  - 35% desert scenery
  - 35% rusted scrap / old cars / weathered metal
  - 20% wildlife / nature
  - 10% sea life
- [ ] Reject candidates that clash with the brand palette:
  - Neon, harsh tropical saturation, muddy fog, dark branch-heavy scenes, generic bright stock nature.
- [ ] Reject candidates that cannot become 16:10 at 3840x2400 or better.

## Task 3: Download and Normalize

- [ ] Download accepted files into `/tmp/wallpaper-candidates/`.
- [ ] Verify each file:

```bash
identify -format '%w %h %f\n' /tmp/wallpaper-candidates/*
```

- [ ] For exact 16:10 files, copy into:

```text
wallpapers/Pictures/walpapers/
```

- [ ] For exceptional near-match files, crop to 16:10 only when the subject remains well framed.

## Task 4: Final Verification

- [ ] Verify every installed wallpaper is 16:10:

```bash
identify -format '%w %h %f\n' wallpapers/Pictures/walpapers/*
```

- [ ] Confirm no installed wallpaper is below 3840x2400.
- [ ] Confirm the final set still reflects the approved subject mix.
- [ ] Run:

```bash
git status --short --branch
```

## Task 5: Review With User

- [ ] Present the installed file list and category summary.
- [ ] If needed, generate a contact sheet so Roi can mark dislikes.
