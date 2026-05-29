<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Topic: Performance Optimization for a High-End Rust-based Dev Stack on Fedora 43

Context:

- OS: Fedora 43 Workstation (Wayland/GNOME 49)
- Hardware: Asus Zenbook 14, Intel i5-1135G7 (Tiger Lake), 16GB RAM, Iris Xe GPU.
- Current Issue: CPU governor is stuck in "powersave" (~1.1GHz), limiting performance for heavy dev tasks.
- Tools: Zed Editor, Claude Code, OpenCode, Zellij (Multiplexer), Alacritty \& Kitty (Terminals).

Research Tasks:

1. CPU \& Power: What is the most efficient way on Fedora 43 to force the "performance" or "schedutil" governor for Intel 11th Gen to unlock the 4.2GHz boost? Compare 'power-profiles-daemon' vs 'auto-cpufreq' for this specific CPU.
2. GPU Acceleration: Provide exact 'vaapi' and Intel Media Driver configurations for Fedora 43 to ensure Zed Editor and Kitty/Alacritty are 100% offloaded to the Iris Xe GPU.
3. Zellij \& Terminals: Find "performance-first" config.kdl examples for Zellij. How to optimize Kitty and Alacritty for minimal input latency on Wayland?
4. Zed Editor Optimization: Are there specific Zed settings or Fedora system tweaks (like process niceness or ionice) to prioritize Zed and Claude Code during heavy compilation/LLM tasks?
5. Asus Zenbook Specifics: Search for "asus-linux" kernel patches or "asusctl" configurations relevant to the 11th Gen Zenbook 14 to optimize thermal overhead and fan curves for sustained performance.

Output: Provide a technical guide with specific GitHub references, sysctl parameters, and DNF commands.

You’ll get the best overall experience by (1) sticking with Fedora’s `power-profiles-daemon` on an intel_pstate/HWP system, forcing the Performance profile when you need it, and (2) making sure the Intel media/Vulkan stack is correctly installed, then tuning Zellij/kitty/Alacritty configs and using `asusctl` for thermals. Below are concrete commands and config snippets.

***

## CPU governor setup on Tiger Lake

On 11th‑gen Intel (Tiger Lake) Fedora uses the `intel_pstate` driver in active/HWP mode, which only exposes the `powersave` and `performance` governors but still allows full turbo up to 4.2 GHz within those policies.[^1][^2]

First, confirm your driver and available governors:

```bash
sudo dnf install kernel-tools
cpupower frequency-info
```

You should see something like:

```text
driver: intel_pstate
hardware limits: 400 MHz - 4.20 GHz
available cpufreq governors: performance powersave
current policy: 400 MHz - 4.20 GHz
The governor "powersave" may decide which speed to use within this range.
boost state support: Supported: yes Active: yes
```


### Using power-profiles-daemon (recommended)

Fedora Workstation ships `power-profiles-daemon` by default and uses it in GNOME’s power UI. It exposes `balanced`, `power-saver`, and (where supported) `performance` profiles backed by the `intel_pstate` driver.[^3][^4][^5]

Install/ensure it’s present:

```bash
sudo dnf install power-profiles-daemon
systemctl status power-profiles-daemon.service
```

CLI control:

```bash
# See current profile
powerprofilesctl get

# List profiles
powerprofilesctl list

# Force Performance profile
powerprofilesctl set performance

# Run a single command under Performance for 5 minutes
powerprofilesctl launch --profile performance --reason "zed-build" --appid "zed" zed
```

On a Tiger Lake CPU this keeps the hardware limits at e.g. 400 MHz–4.2 GHz with turbo active, but biases the hardware power controller toward higher performance versus `powersave`.[^6][^2]

### Using auto-cpufreq (when it makes sense)

[`auto-cpufreq`](https://github.com/AdnanHodzic/auto-cpufreq) is a daemon that dynamically adjusts governor, EPP, and turbo depending on AC/battery state. When installed, it **disables GNOME Power Profiles / power-profiles-daemon** to avoid conflicts.[^7]

For a mostly‑on‑AC dev laptop, its main advantage is automatic switching when you unplug/plug, not higher peak clocks: with `intel_pstate`+HWP both tools end up exposing the same turbo range. In practice:[^8][^2]

- Prefer **`power-profiles-daemon`** if you:
    - Are fine manually toggling profiles (GNOME menu or `powerprofilesctl`).
    - Want tight integration with GNOME/KDE.[^4][^5]
- Prefer **`auto-cpufreq`** if you:
    - Move between battery and AC all the time and want aggressive automatic tuning.

If you do install auto‑cpufreq, let it manage things fully and keep `power-profiles-daemon` disabled, as recommended in its README.[^7]

### Forcing classic governors (schedutil / performance)

If you explicitly want `schedutil`, `ondemand`, etc., you must move `intel_pstate` out of active mode and let `acpi_cpufreq` / cpufreq handle governors.[^8][^1]

1. Edit GRUB:

```bash
sudo nano /etc/default/grub
```

Add either:
    - Passive `intel_pstate` (so you can use `schedutil`):

```text
GRUB_CMDLINE_LINUX="... intel_pstate=passive"
```[^9][^1]
```

    - Or fully disable it (use ACPI cpufreq + full governor set):

```text
GRUB_CMDLINE_LINUX="... intel_pstate=disable"
```[^8]

```

2. Rebuild GRUB (on UEFI Fedora):

```bash
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
sudo reboot
```

3. After reboot:

```bash
cpupower frequency-info
# Should now show a cpufreq driver, with governors like schedutil/ondemand/performance/etc.
```

4. To force `performance`:

```bash
sudo cpupower frequency-set -g performance
sudo systemctl enable --now cpupower.service
```[^10][^1]

```


### Optional sysctl for memory behavior

Fedora’s docs show combining a better governor with reduced `vm.swappiness` for snappier desktop behavior.[^10]

Create `/etc/sysctl.d/99-performance.conf`:

```bash
sudo tee /etc/sysctl.d/99-performance.conf << 'EOF'
vm.swappiness = 10
EOF

sudo sysctl --system
```


***

## GPU and VAAPI on Iris Xe

On Fedora 43, Intel integrated graphics (Iris Xe) use the in‑kernel `i915`/`xe` drivers plus Intel firmware; no separate “driver install” is usually needed.[^11]

### Install Intel media \& VAAPI stack

Fedora’s Intel graphics best‑practices doc recommends installing VAAPI and Intel media components plus tools:[^12]

```bash
# Multimedia group and Intel VAAPI stack
sudo dnf groupinstall multimedia

sudo dnf install \
  intel-media-driver \
  libva libva-utils \
  gstreamer1-vaapi ffmpeg \
  intel-gpu-tools \
  mesa-dri-drivers mpv
```

`intel-media-driver` (packaged as `libva-intel-media-driver`) is the modern VAAPI user-mode driver for Gen9+ (including Iris Xe); Fedora 43 ships version 25.4.6‑1.fc43.[^13]

Verify VAAPI:

```bash
vainfo | grep -E 'Driver version|Iris|VAProfile'
```

You should see `Driver: Intel iHD driver` or similar, confirming the `iHD` driver is used for VAAPI decode/encode.[^13][^12]

If apps choose the wrong VAAPI driver, force it via environment:

```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/vaapi.conf <<EOF
LIBVA_DRIVER_NAME=iHD
EOF
```

Log out/in and re‑run `vainfo` to confirm.[^12]

### Zed GPU acceleration (Vulkan)

Zed uses Vulkan via `wgpu` and **requires** a working Vulkan stack; if it can’t find a GPU, it falls back to llvmpipe with terrible performance.[^14][^15][^16]

Install Vulkan tools and Mesa’s Vulkan drivers:

```bash
sudo dnf install vulkan-tools mesa-vulkan-drivers
```

Test Vulkan:

```bash
vulkaninfo | less   # should enumerate your Intel GPU
vkcube             # spinning cube rendered by GPU, not llvmpipe
```

Run Zed and watch GPU usage:

```bash
intel_gpu_top     # from intel-gpu-tools
```

When scrolling or editing in Zed, you should see GPU 3D engine activity, confirming rendering is offloaded.[^15][^12]

There are no extra “Zed VAAPI” knobs to turn; once Vulkan + Mesa + Intel media are configured, Zed is fully GPU‑backed.[^17][^15]

### Kitty/Alacritty GPU usage

Kitty and Alacritty are already GPU‑accelerated terminals (OpenGL/Vulkan where available); with a correct Mesa/Intel stack they render entirely on the iGPU.[^18][^19]

- Kitty caches glyphs in VRAM and uses minimal CPU per frame.[^20]
- Alacritty uses OpenGL and is designed as a “blazingly fast, GPU‑accelerated” terminal emulator.[^19]

Again, `intel_gpu_top` is your friend: hold a key to scroll in `less` inside kitty/Alacritty and you should see 3D engine activity on the Iris Xe.[^12]

VAAPI is only relevant for video decode/encode (mpv, browsers, etc.), not for terminals or Zed. Ensuring the VAAPI stack works is still useful for video playback and GPU‑accelerated dev tooling, but not directly for kitty/Alacritty rendering.

***

## Zellij and terminals for low latency

### Zellij “performance‑first” config.kdl

Start from the default config, then trim features that add CPU/IO overhead (large scrollback, heavy serialization, decorative UI):

```bash
mkdir -p ~/.config/zellij
zellij setup --dump-config > ~/.config/zellij/config.kdl
```

Key options from the Zellij options docs:[^21][^22]

- `pane_frames` – draw borders around panes.[^21]
- `scroll_buffer_size` – scrollback lines per pane (default 10000).[^22][^21]
- `session_serialization` / `scrollback_lines_to_serialize` / `serialization_interval` – background persistence of pane content; more work = more resource usage.[^22][^21]

Example “performance‑first” snippet in `~/.config/zellij/config.kdl`:

```kdl
// Minimal UI, no mouse, smaller scrollback
simplified_ui true
mouse_mode false
pane_frames false
scroll_buffer_size 5000

// Disable heavy session serialization
session_serialization false
scrollback_lines_to_serialize 0
serialization_interval 0
```

Each of these keys is documented as a top‑level configuration option and disabling serialization explicitly trades disk/cpu overhead for lower runtime costs.[^21][^22]

For even leaner behavior you can also disable startup tips and fanciness, as in this common minimal config:[^23]

```kdl
simplified_ui false
theme "pencil-light"
default_layout "compact"
mouse_mode false
pane_frames false
show_startup_tips false
```


### Kitty low-latency settings on Wayland

Kitty exposes explicit performance knobs: `repaint_delay`, `input_delay`, and `sync_to_monitor`. The docs recommend the following for minimum keyboard‑to‑screen latency (higher CPU usage, possible tearing):[^24][^20][^18]

In `~/.config/kitty/kitty.conf`:

```conf
# Lowest latency settings
input_delay 0
repaint_delay 2
sync_to_monitor no
wayland_enable_ime no
```

- `input_delay` is an artificial delay before processing input; lowering to `0` reduces latency at the cost of more CPU.[^20]
- `repaint_delay` controls how often kitty repaints; `2` ms is very aggressive.[^24][^20]
- `sync_to_monitor no` disables vsync, reducing latency further but potentially introducing tearing.[^18][^20]

These values are explicitly documented as the “minimize latency” settings in kitty’s performance documentation.[^20][^18]

### Alacritty on Wayland

Alacritty doesn’t expose as many latency‑tuning knobs, but a few points help:

- It already targets low input latency and throughput using a GPU backend.[^19]
- On Wayland, Alacritty uses the Wayland backend by default; you can explicitly run an XWayland instance via `env WAYLAND_DISPLAY= alacritty` if you suspect Wayland backend issues, but that adds an extra layer.[^25][^26]

You can reduce scrollback workload by lowering history in `alacritty.toml` (or `alacritty.yml` on older versions):

```toml
[scrolling]
history = 5000   # default is 10000
```

The manual notes this cap and its impact on memory; smaller values slightly reduce processing overhead on huge scrollback buffers.[^27]

Since Alacritty’s configuration is hot‑reloaded (`live_config_reload`), you can tweak and observe impact in real time.[^28]

***

## Zed prioritization on Fedora

Zed itself doesn’t currently expose “performance profile” toggles beyond its normal settings; official docs focus on making sure Vulkan is working (and that you’re not on llvmpipe) rather than tunable performance knobs. So the wins here are mostly system‑level:[^29][^15][^17]

### Run Zed in a higher‑priority scope

You can give Zed a higher CPU and IO weight via a transient `systemd` user scope:

```bash
systemd-run --user --scope \
  -p CPUWeight=200 \
  -p IOWeight=200 \
  zed
```

Within cgroups, `CPUWeight` and `IOWeight` >100 bias the scheduler toward that scope when there’s contention, which helps Zed/Claude Code stay responsive during heavy compiles.

Or just launch via classic `nice`/`ionice`:

```bash
nice -n -5 ionice -c2 -n0 zed
```

This de‑prioritizes other normal (`nice 0`) processes relative to Zed.

### Keep Zed off llvmpipe

If you ever see messages like “Zed uses Vulkan for rendering and requires a compatible GPU. Currently you are using llvmpipe…”, follow the Vulkan troubleshooting guide (install `vulkan-tools`, `mesa-vulkan-drivers`, run `vkcube`, etc.). Staying on real GPU drivers does far more for interactivity than any tweak.[^16][^14][^15]

For large monorepos, Zed’s background indexing is known to be a one‑time cost; letting that complete and keeping the project cache on a fast NVMe (your Zenbook already has it) is generally enough.[^17]

***

## Asus Zenbook‑specific tuning (asusctl)

The Asus Zenbook 14 i5‑1135G7 isn’t an ROG machine, but the `asusctl`/`asusd` stack from the **asus‑linux** project supports many non‑ROG laptops with at least profile and some thermal controls. Fedora is explicitly supported and has a dedicated setup guide.[^30][^31]

### Install asusctl and supergfxctl on Fedora

Enable the COPR repo and install the tools:

```bash
# 1. Enable Asus Linux COPR
sudo dnf copr enable lukenukem/asus-linux
sudo dnf update

# 2. Install tools
sudo dnf install asusctl supergfxctl

# 3. Enable daemons
sudo systemctl enable --now asusd.service
sudo systemctl enable --now supergfxd.service
```

For Zenbooks without a dGPU, `supergfxctl` may offer limited functionality, but asusd still provides power profiles and some platform controls.[^32][^30]

### Profiles and fan curves

- `asusctl` implements “Quiet”, “Balanced”, and “Performance” profiles, which are tied into the EC’s built‑in power/fan curves and can be selected from CLI or the optional GUI (`asusctl-rog-gui` / ROG Control Center).[^33][^34]
- The asus‑linux FAQ and manual note that **custom fan curves** (editing specific temperature–RPM points) are currently only supported on Ryzen ROG laptops; on Intel Zenbooks you typically get fixed curves per profile instead.[^35][^33]

You can still inspect and, where supported, tweak profile configuration in `/etc/asusd/profile.conf`, which is populated from EC defaults on first run. For example, ROG machines expose fan curve tables like:[^35]

```text
CPU: enabled: true, 55c:4%,60c:9%,65c:29%,68c:46%,72c:67%,76c:83%,96c:100%,97c:100%
```

On your Zenbook, expect:

- Switching to **Performance** profile in `asusctl` to raise PL1/PL2 power and allow higher sustained clocks and more aggressive fans.
- Quiet/Balanced to lower sustained power and fan noise.

Core commands:

```bash
# Show current profile
asusctl profile -g

# Cycle profiles (Quiet, Balanced, Performance)
asusctl profile -n
```

`asusctl` and `asusd` are designed to be very light (sub‑1 MB RAM, negligible CPU), so enabling them won’t hurt performance.[^30][^32]

***

## Putting it all together

For your specific Fedora 43 + Zenbook 14 + Rust dev stack, a sane “max performance” routine is:

1. **Before heavy work** (compiles, LLM runs):
    - `powerprofilesctl set performance` (or auto‑cpufreq on AC if you prefer).[^3][^4][^7]
    - Switch `asusctl` profile to Performance.
2. **Ensure GPU stack is correct**:
    - Install `intel-media-driver`, `libva-utils`, `intel-gpu-tools`, `mesa-vulkan-drivers`, run `vainfo`, `vulkaninfo`, `vkcube`, and check `intel_gpu_top` under Zed/kitty.[^15][^13][^12]
3. **Use tuned configs**:
    - Zellij: smaller `scroll_buffer_size`, disabled pane frames and serialization.[^23][^22][^21]
    - Kitty: `input_delay 0`, `repaint_delay 2`, `sync_to_monitor no`, `wayland_enable_ime no`.[^18][^24][^20]
4. **Launch Zed in a higher‑priority scope** via `systemd-run` or `nice`/`ionice` during really heavy LLM/compile sessions.

If you want, I can take your current `config.kdl`, `kitty.conf`, and `alacritty.toml` and hand‑edit them into a cohesive “performance profile” tailored exactly to your workflow.
<span style="display:none">[^100][^101][^102][^103][^104][^105][^106][^107][^108][^109][^110][^111][^112][^113][^114][^115][^116][^117][^118][^119][^120][^121][^122][^123][^124][^125][^126][^127][^128][^129][^130][^131][^132][^133][^134][^135][^136][^137][^138][^139][^140][^141][^142][^143][^144][^145][^146][^36][^37][^38][^39][^40][^41][^42][^43][^44][^45][^46][^47][^48][^49][^50][^51][^52][^53][^54][^55][^56][^57][^58][^59][^60][^61][^62][^63][^64][^65][^66][^67][^68][^69][^70][^71][^72][^73][^74][^75][^76][^77][^78][^79][^80][^81][^82][^83][^84][^85][^86][^87][^88][^89][^90][^91][^92][^93][^94][^95][^96][^97][^98][^99]</span>

<div align="center">⁂</div>

[^1]: https://discussion.fedoraproject.org/t/cpu-scaling-governor-issues/76968

[^2]: https://discussion.fedoraproject.org/t/sluggish-despite-performance-power-mode/101996

[^3]: https://sleeplessbeastie.eu/2022/09/12/how-to-control-power-profiles-daemon-using-command-line/

[^4]: https://fedoraproject.org/wiki/Changes/Power_Profiles_Daemon

[^5]: https://linuxconfig.org/how-to-manage-power-profiles-over-d-bus-with-power-profiles-daemon-on-linux

[^6]: https://forum.garudalinux.org/t/intel-pstate-power-governor-default-explained/20069

[^7]: https://github.com/AdnanHodzic/auto-cpufreq

[^8]: https://www.reddit.com/r/Fedora/comments/fvgo4g/power_saving_governors_intel_pstate_down_that/

[^9]: https://www.reddit.com/r/Fedora/comments/o72h46/bad_performance_with_default_cpu_governor/

[^10]: https://discussion.fedoraproject.org/t/how-to-increasing-performance-by-changing-cpu-governor-and-reducing-swappiness/71429

[^11]: https://www.reddit.com/r/Fedora/comments/1q2qmzm/intel_drivers/

[^12]: https://discussion.fedoraproject.org/t/intel-graphics-best-practices-and-settings-for-hardware-acceleration/69944

[^13]: https://packages.fedoraproject.org/pkgs/intel-media-driver-free/libva-intel-media-driver/index.html

[^14]: https://forums.opensuse.org/t/vulkan-error-when-starting-zed/187419

[^15]: https://zed.dev/docs/linux

[^16]: https://github.com/zed-industries/zed/discussions/17212

[^17]: https://www.deployhq.com/guides/zed

[^18]: https://sw.kovidgoyal.net/kitty/performance/

[^19]: https://dotcommagazine.com/2024/07/alacritty-a-comprehensive-guide-2/

[^20]: https://github.com/kovidgoyal/kitty/blob/master/docs/performance.rst

[^21]: https://zellij.dev/documentation/options.html

[^22]: https://zellij.dev/documentation/options.html?highlight=interval

[^23]: https://lofic.github.io/tips/zellij-config.html

[^24]: https://www.reddit.com/r/linux/comments/1jcrvmi/has_alacritty_become_significantly_faster_a_newer/

[^25]: https://github.com/alacritty/alacritty/issues/1909

[^26]: https://github.com/alacritty/alacritty/issues/97

[^27]: https://alacritty.org/config-alacritty.html

[^28]: https://wiki.archlinux.org/title/Alacritty

[^29]: https://github.com/zed-industries/zed/issues/14088

[^30]: https://gitmemories.com/flukejones/asusctl

[^31]: https://asus-linux.org/guides/fedora-guide/

[^32]: https://asus-linux.org/faq/

[^33]: https://asus-linux.org/faq/asusctl/custom-fan-curves/

[^34]: https://hiiruki.com/blog/install-rog-control-center-fedora-linux/

[^35]: https://asus-linux.org/manual/asusctl-manual/

[^36]: https://superfri.org/superfri/article/download/118/208

[^37]: https://rajpub.com/index.php/ijct/article/download/2536ijct/pdf_455

[^38]: https://arxiv.org/pdf/2005.02947.pdf

[^39]: https://arxiv.org/pdf/1004.4431v2.pdf

[^40]: https://arxiv.org/pdf/2210.03724.pdf

[^41]: https://academic.oup.com/comjnl/article-pdf/60/1/60/10329287/bxw065.pdf

[^42]: https://arxiv.org/pdf/2206.07012.pdf

[^43]: https://www.mdpi.com/1996-1073/13/9/2409/pdf

[^44]: https://discussion.fedoraproject.org/t/fedora-not-applying-custom-fan-curves-set-via-asusctl-until-i-switch-profiles/161725

[^45]: https://www.reddit.com/r/Fedora/comments/1cgf5oh/powerprofilesdaemon_vs_autocpufreq_battery_life/

[^46]: https://bugzilla.mozilla.org/show_bug.cgi?id=1760941

[^47]: https://www.reddit.com/r/ZephyrusG14/comments/rgvrrk/edit_fan_curve_on_linux/

[^48]: https://www.reddit.com/r/Fedora/comments/1izi4tv/asusctl_fan_always_running_despite_lower/

[^49]: https://www.reddit.com/r/Fedora/comments/1ap87k2/cpu_governor_stuck_at_powersave/

[^50]: https://forums.rockylinux.org/t/rocky-linux-8-7-how-to-install-intel-media-driver/9933

[^51]: https://ijcesen.com/index.php/ijcesen/article/view/4303

[^52]: https://ieeexplore.ieee.org/document/10590455/

[^53]: https://ieeexplore.ieee.org/document/10768229/

[^54]: https://cic.iacr.org/p/1/4/25

[^55]: https://ieeexplore.ieee.org/document/10273490/

[^56]: https://ieeexplore.ieee.org/document/10226129/

[^57]: https://www.mdpi.com/2079-9292/12/2/364

[^58]: https://dx.plos.org/10.1371/journal.pone.0339035

[^59]: https://dl.acm.org/doi/10.1145/3623509.3633366

[^60]: https://www.semanticscholar.org/paper/1ffb9f6abca33425ebc3495bbeaf0f96c997ab78

[^61]: http://arxiv.org/pdf/2503.21289.pdf

[^62]: https://arxiv.org/html/2504.03775v1

[^63]: https://arxiv.org/pdf/2402.01480.pdf

[^64]: http://arxiv.org/pdf/2410.11554.pdf

[^65]: https://arxiv.org/pdf/2402.03183.pdf

[^66]: http://arxiv.org/pdf/2502.20522.pdf

[^67]: https://arxiv.org/pdf/2408.17171.pdf

[^68]: https://arxiv.org/html/2503.11663v1

[^69]: https://github.com/zellij-org/zellij/issues/443

[^70]: https://zellij.dev/documentation/configuration.html

[^71]: https://bbs.archlinux.org/viewtopic.php?id=308119

[^72]: https://zellij.dev/news/config-command-layouts/

[^73]: https://peterbabic.dev/blog/make-auto-type-work-kitty-wayland/

[^74]: https://github.com/zellij-org/zellij/issues/569

[^75]: https://github.com/kovidgoyal/kitty/issues/2648

[^76]: https://github.com/zellij-org/zellij/blob/main/zellij-utils/assets/config/default.kdl

[^77]: http://ieeexplore.ieee.org/document/6597191/

[^78]: http://www.tandfonline.com/doi/abs/10.1080/19401493.2011.599157

[^79]: https://jacow.org/ipac2021/doi/JACoW-IPAC2021-TUPAB016.html

[^80]: https://www.semanticscholar.org/paper/4995b36c084007875eb2d917dea2b2de2712792b

[^81]: https://www.semanticscholar.org/paper/9f1ffdc00d67e05cdc974299462eca0f19778096

[^82]: https://www.semanticscholar.org/paper/54fb9277cd8e0000148f3f0ba0f0563b97b8e980

[^83]: https://www.semanticscholar.org/paper/7d679535ba9d0106474fe33aef47c756385a9c67

[^84]: https://jnnp.bmj.com/lookup/doi/10.1136/jnnp.49.4.474

[^85]: https://iopscience.iop.org/article/10.1149/MA2025-03121mtgabs

[^86]: https://journal.media-culture.org.au/index.php/mcjournal/article/view/2965

[^87]: https://arxiv.org/pdf/1811.01412.pdf

[^88]: https://arxiv.org/pdf/2401.17168.pdf

[^89]: https://arxiv.org/pdf/1710.03439.pdf

[^90]: https://arxiv.org/pdf/2405.02106.pdf

[^91]: https://arxiv.org/pdf/2112.11767.pdf

[^92]: https://arxiv.org/html/2411.02797

[^93]: https://www.percona.com/blog/cpu-governor-performance/

[^94]: https://github.com/alacritty/alacritty/issues/4253

[^95]: https://github.com/alacritty/alacritty/issues/5756

[^96]: https://discussion.fedoraproject.org/t/how-to-switch-profiles-of-power-profiles-daemon-automatically-on-kde-plasma/34071

[^97]: https://github.com/Rongronggg9/power-profiles-daemon/blob/ds/README.md

[^98]: https://discuss.kde.org/t/plasma-5-wayland-only-shows-latency-under-composing/9632

[^99]: https://arxiv.org/html/2410.00026

[^100]: http://arxiv.org/pdf/2405.04355.pdf

[^101]: http://arxiv.org/pdf/2301.13421.pdf

[^102]: https://dl.acm.org/doi/pdf/10.1145/3698576.3698766

[^103]: https://dl.acm.org/doi/pdf/10.1145/3580601

[^104]: https://zenodo.org/records/7767318/files/ASPLOS23.pdf

[^105]: https://arxiv.org/pdf/2304.11002.pdf

[^106]: https://www.journalijar.com/article/35948/advance-technology-for-linux-user-with-better-security/

[^107]: https://forum.endeavouros.com/t/endevour-on-asus-zenbook-14-oled/64187

[^108]: https://www.reddit.com/r/linuxhardware/comments/1k0heh3/linux_compatibility_on_asus_zenbook_s_14_oled/

[^109]: https://pokde.net/review/asus-zenbook-14-ux425ea-review

[^110]: https://asus-linux.org/guides/arch-guide/

[^111]: https://asustuf.gitbook.io/home/linux/linux/installing-linux

[^112]: https://wiki.archlinux.org/title/Laptop/ASUS

[^113]: https://discussion.fedoraproject.org/t/no-sound-from-speakers-after-resume-on-acer-zenbook-ux325ea-tiger-lake-laptop/102646

[^114]: https://www.reddit.com/r/ZephyrusG14/comments/l5q1ip/complete_newbies_guide_to_getting_fedora_linux_on/

[^115]: https://www.reddit.com/r/linuxhardware/comments/1hutm6o/linux_on_asus_laptops/

[^116]: https://www.linux.org/threads/installing-on-asus-zenbook-flip-15.33591/

[^117]: https://asus-linux.org/guides/asusctl-install/

[^118]: http://arxiv.org/pdf/2501.15392.pdf

[^119]: https://arxiv.org/pdf/2304.14908.pdf

[^120]: https://arxiv.org/pdf/2501.15475.pdf

[^121]: http://arxiv.org/pdf/2411.10559.pdf

[^122]: https://www.mdpi.com/2079-9292/10/11/1331/pdf?version=1622626599

[^123]: https://arxiv.org/pdf/2409.16480.pdf

[^124]: https://www.reddit.com/r/HelixEditor/comments/10ebsia/anybody_notice_sluggish_performance_when_using/

[^125]: https://www.youtube.com/watch?v=PWBqNJRO-og

[^126]: https://github.com/zellij-org/zellij/issues/3785

[^127]: https://www.reddit.com/r/tmux/comments/1cvj0bt/zellijlike_tmux_setup/

[^128]: https://fig.io/manual/zellij/options

[^129]: https://github.com/zellij-org/zellij/issues/3598

[^130]: https://zellij.dev/documentation/creating-a-layout.html

[^131]: https://skillsmp.com/skills/wcygan-dotfiles-claude-skills-zellij-config-skill-md

[^132]: https://github.com/zellij-org/zellij/blob/main/example/config.kdl

[^133]: https://arxiv.org/pdf/2109.02922.pdf

[^134]: http://arxiv.org/pdf/2203.02550v1.pdf

[^135]: https://arxiv.org/pdf/2404.06156.pdf

[^136]: http://downloads.hindawi.com/archive/2015/261094.pdf

[^137]: https://www.mankier.com/5/alacritty

[^138]: https://github.com/alacritty/alacritty/issues/673

[^139]: https://alacritty.org/releases/0.14.0/config-alacritty.html

[^140]: https://man.archlinux.org/man/alacritty.5

[^141]: https://www.reddit.com/r/linux/comments/jc9ipw/why_do_all_newer_terminal_emulators_have_such_bad/

[^142]: https://github.com/alacritty/alacritty/issues/1499

[^143]: https://github.com/alacritty/alacritty/issues/6844

[^144]: https://news.ycombinator.com/item?id=19477297

[^145]: https://github.com/alacritty/alacritty/issues/2643

[^146]: https://man.freebsd.org/cgi/man.cgi?query=alacritty\&sektion=5\&manpath=FreeBSD+15.0-RELEASE+and+Ports

