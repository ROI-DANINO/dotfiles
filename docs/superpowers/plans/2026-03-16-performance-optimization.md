# Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Activate the performance CPU profile, install Intel GPU/VAAPI tooling, reduce swappiness, and enable Zellij's simplified UI — all minimal-risk, high-reward changes.

**Architecture:** One dotfile edit committed to the dotfiles repo; three system-level changes run manually with sudo. No kernel parameter changes, no reboots required (sysctl applies live).

**Tech Stack:** Zellij KDL config, DNF, systemd, sysctl, powerprofilesctl

---

## Chunk 1: Dotfile — Zellij simplified_ui

**Scope note:** Only `simplified_ui true` is applied in this run. `pane_frames`, `scroll_buffer_size`, and Alacritty changes are intentionally deferred for separate evaluation.

### Task 1: Enable `simplified_ui` in Zellij config

**Files:**
- Modify: `zellij/config.kdl:280`
- Backup: `zellij/config.kdl.bak`

- [ ] **Step 1: Verify config is valid before touching it**

```bash
zellij setup --check 2>&1
```

Expected: no errors. This establishes a known-good baseline — if it already errors, stop and investigate before editing.

- [ ] **Step 2: Back up the config**

```bash
cp /home/roking/dotfiles/zellij/config.kdl \
   /home/roking/dotfiles/zellij/config.kdl.bak
```

Expected: no output, file `config.kdl.bak` appears alongside `config.kdl`.

- [ ] **Step 3: Uncomment `simplified_ui true`**

In `zellij/config.kdl` line 280, change:

```kdl
// simplified_ui true
```

to:

```kdl
simplified_ui true
```

- [ ] **Step 4: Verify the file parses**

```bash
zellij setup --check 2>&1 || echo "config error"
```

Expected: either clean output (no errors) or "config error" if Zellij reports a parse problem. If it errors, revert from backup and stop.

- [ ] **Step 5: Commit**

```bash
cd /home/roking/dotfiles
git add zellij/config.kdl
git commit -m "perf: enable simplified_ui in zellij config"
```

Expected: commit created on `master`.

---

## Chunk 2: System — Power Profile Daemon

### Task 2: Install and activate power-profiles-daemon

**Note:** These steps require `sudo`. Run in your terminal, not through Claude.

- [ ] **Step 1: Install power-profiles-daemon**

```bash
sudo dnf install -y power-profiles-daemon
```

Expected: DNF resolves and installs the package. If already installed, DNF says "Nothing to do."

- [ ] **Step 2: Enable and start the service**

```bash
sudo systemctl enable --now power-profiles-daemon
```

Expected: no errors; service starts immediately.

- [ ] **Step 3: Set performance profile**

```bash
powerprofilesctl set performance
```

Expected: no output (success is silent).

- [ ] **Step 4: Verify**

```bash
powerprofilesctl get
```

Expected output:

```
performance
```

---

## Chunk 3: System — Intel GPU & VAAPI Stack

### Task 3: Install Intel media driver and GPU tools

**Note:** These steps require `sudo`.

- [ ] **Step 1: Install packages**

```bash
sudo dnf install -y intel-media-driver libva-utils intel-gpu-tools vulkan-tools
```

Expected: DNF installs all four packages. Note: `intel-media-driver` may be named `libva-intel-media-driver` in the repo — DNF will resolve either.

- [ ] **Step 2: Verify VAAPI**

```bash
vainfo 2>&1 | grep -E "Driver version|iHD|Iris"
```

Expected: output containing `iHD` or `Intel iHD driver`. If you see `i965` or no output, the wrong driver is active — set `LIBVA_DRIVER_NAME=iHD` in `~/.config/environment.d/vaapi.conf` and log out/in.

- [ ] **Step 3: Verify Vulkan**

```bash
vulkaninfo 2>/dev/null | grep deviceName
```

Expected: a line containing `Intel` and `Iris Xe` (or similar). Must NOT show `llvmpipe`. If llvmpipe appears, Zed is using software rendering — investigate Mesa installation.

- [ ] **Step 4: Spot-check GPU activity (optional but recommended)**

Open `intel_gpu_top` in one terminal, open Zed in another, scroll around:

```bash
sudo intel_gpu_top
```

Expected: non-zero activity in the `Render/3D` row while Zed is rendering. Confirms GPU acceleration is live.

---

## Chunk 4: System — Swappiness Tuning

### Task 4: Set vm.swappiness = 10

**Note:** Requires `sudo`. Change applies immediately — no reboot needed.

- [ ] **Step 1: Write sysctl config**

```bash
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-performance.conf
```

Expected output:

```
vm.swappiness = 10
```

- [ ] **Step 2: Apply immediately**

```bash
sudo sysctl --system 2>&1 | grep swappiness
```

Expected output (among other lines):

```
* Applying /etc/sysctl.d/99-performance.conf ...
vm.swappiness = 10
```

- [ ] **Step 3: Confirm current value**

```bash
cat /proc/sys/vm/swappiness
```

Expected:

```
10
```

- [ ] **Step 4: Verify file persists across reboot**

```bash
cat /etc/sysctl.d/99-performance.conf
```

Expected:

```
vm.swappiness = 10
```

This file is read on every boot — no further action needed.
