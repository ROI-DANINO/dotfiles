# Performance Optimization — Fedora 43 / Zenbook 14 (i5-1135G7)

**Date:** 2026-03-16
**Hardware:** Asus Zenbook 14, Intel i5-1135G7 (Tiger Lake), 16GB RAM, Iris Xe GPU
**OS:** Fedora 43 Workstation (Wayland)
**Stack:** Zed, Claude Code, Zellij, Kitty (excluded — no changes), Alacritty

---

## Goal

Improve desktop responsiveness and sustained performance during heavy dev tasks (Rust compilation, LLM inference) by:
1. Activating the `performance` CPU power profile
2. Installing the Intel VAAPI/Vulkan stack to ensure GPU acceleration is working
3. Reducing memory pressure via swappiness tuning
4. Trimming terminal multiplexer overhead in Zellij and Alacritty

---

## Scope

### In scope
- Zellij config: reduce UI and scrollback overhead
- Alacritty config: reduce scrollback
- System packages: VAAPI driver, GPU tooling, power-profiles-daemon
- Sysctl: vm.swappiness
- Power profile: set to performance

### Out of scope
- Kitty config (no changes — already optimal for this setup)
- asusctl (already installed and on Performance profile)
- Zed editor settings
- GRUB / kernel parameter changes
- auto-cpufreq (conflicts with power-profiles-daemon)

---

## Current State (verified)

| Item | State |
|------|-------|
| `kernel-tools` | installed |
| `mesa-vulkan-drivers` | installed |
| `asusctl` | installed, profile = Performance |
| `power-profiles-daemon` | NOT installed |
| `intel-media-driver` | NOT installed |
| `libva-utils` | NOT installed |
| `intel-gpu-tools` | NOT installed |
| `vulkan-tools` | NOT installed |
| `/etc/sysctl.d/99-performance.conf` | does not exist |

---

## Phase 1 — Dotfile Edits (applied by Claude, committed to repo)

### Zellij: `zellij/config.kdl`

**Scope note:** After review, only the single lowest-risk, highest-reward Zellij option is included in this implementation run. `pane_frames`, `scroll_buffer_size`, and Alacritty changes are intentionally deferred — they carry visible trade-offs and can be applied independently later.

| Option | Value | Reason |
|--------|-------|--------|
| `simplified_ui` | `true` | Disables powerline/arrow glyphs in status bar, reduces font-shaping work. Zero visual disruption to pane layout. |

Deferred (out of scope for this run):
- `pane_frames false` — removes pane borders (user wants to evaluate separately)
- `scroll_buffer_size 5000` — reduces scrollback (user wants to evaluate separately)
- `session_serialization false` — user preference to keep session resurrection

### Alacritty: `alacritty/alacritty.toml`

Deferred — `scrolling.history` reduction is intentionally out of scope for this run.

**Backup policy:** File is copied to `<filename>.bak` before editing.

---

## Phase 2 — System Changes (run manually, in order)

### Step 1: Power profile daemon

```bash
sudo dnf install -y power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon
powerprofilesctl set performance
```

**Effect:** Biases the CPU's Energy Performance Preference toward higher sustained clocks. On Tiger Lake with `intel_pstate`, both `powersave` and `performance` allow full 4.2GHz turbo, but `performance` stays there longer under load instead of dropping clocks aggressively between bursts.

**Note on asusctl coexistence:** `asusctl`/`asusd` manages Asus platform power profiles (fan curves, TDP via EC) while `power-profiles-daemon` manages the CPU governor EPP hint — these operate at different layers and generally coexist. However, if conflicts arise (e.g. profiles fighting each other), disabling one is the fix. Monitor with `powerprofilesctl get` and `asusctl profile get` after setup.

### Step 2: Intel VAAPI + GPU tooling

```bash
sudo dnf install -y intel-media-driver libva-utils intel-gpu-tools vulkan-tools
```

| Package | Purpose |
|---------|---------|
| `intel-media-driver` | VAAPI driver for Iris Xe — enables hardware video decode/encode |
| `libva-utils` | Provides `vainfo` to verify VAAPI is working |
| `intel-gpu-tools` | Provides `intel_gpu_top` to monitor GPU usage in real time |
| `vulkan-tools` | Provides `vulkaninfo` + `vkcube` to verify Zed's Vulkan path |

### Step 3: Reduce swappiness

```bash
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-performance.conf
sudo sysctl --system
```

**Effect:** Linux default is 60 — it swaps RAM to disk well before memory is full. At 10, the kernel holds onto RAM much more aggressively, keeping Zed, the compiler, and Claude Code in memory longer and reducing random disk stall events.

---

## Phase 3 — Validation

```bash
# Confirm performance profile is active
powerprofilesctl get

# Confirm CPU boost is active and governor is set
cpupower frequency-info

# Verify VAAPI (should show "Intel iHD driver")
vainfo

# Verify Vulkan — confirm GPU is used, not llvmpipe (software rendering)
vulkaninfo 2>/dev/null | grep deviceName   # should show "Intel Iris Xe", NOT "llvmpipe"
vkcube                                      # spinning cube; also watch intel_gpu_top in another terminal

# Monitor GPU activity while using Zed / running a build
sudo intel_gpu_top
```

---

## Trade-offs Accepted

| Change | Trade-off |
|--------|-----------|
| `simplified_ui true` | Status bar looks plainer (no arrow glyphs) |
| `vm.swappiness 10` | If RAM is genuinely exhausted, OOM killer hits faster than with swapping |
| `performance` profile | Higher power draw and fan activity under load |

Deferred options (not applied in this run — trade-offs to evaluate separately):
- `pane_frames false` — pane borders gone, slightly harder to distinguish panes visually
- `scroll_buffer_size 5000` / `scrolling.history 5000` — less scrollback history
