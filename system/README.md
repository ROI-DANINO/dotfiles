# System Configuration Reference

**IMPORTANT:** These files are NOT applied by `setup.sh`. Apply them manually per machine. Use Claude Code to review each one before applying.

This directory contains system-level configuration files for kernel tuning, memory management, and logging. Each requires manual deployment to their respective system locations and service restarts.

---

## sysctl — Kernel Tuning

Kernel parameters that optimize memory and network behavior.

### 99-memory-optimization.conf
Optimizes memory management for systems with limited RAM or frequent memory pressure:

```bash
sudo cp system/sysctl/99-memory-optimization.conf /etc/sysctl.d/
sudo sysctl --system
```

**What it does:**
- `vm.swappiness=10` — Strongly prefer RAM over swap
- `vm.vfs_cache_pressure=150` — Aggressively free inode/dentry caches
- `vm.compaction_proactiveness=20` — Improve memory compaction for fragmentation
- `vm.page-cluster=0` — Reduce swap read-ahead overhead

### 99-network-tuning.conf
Optimizes TCP/IP stack for low-latency networks and API-heavy workloads:

```bash
sudo cp system/sysctl/99-network-tuning.conf /etc/sysctl.d/
sudo sysctl --system
```

**What it does:**
- BBR congestion control — Better handling of variable WiFi latency
- `fq` queuing discipline — Fair queuing at network layer
- TCP buffer tuning — 8 MB max, dynamic scaling (4K–4M range)
- MTU probing — Detects optimal packet size automatically
- TCP Fast Open — Reduces handshake overhead for repeated connections

---

## zram — Compressed Swap in RAM

Compressed memory pool for swap, reducing disk I/O on memory pressure.

### zram/zram-generator.conf
Configures zRAM block device via systemd-zram-setup:

```bash
sudo cp system/zram/zram-generator.conf /etc/systemd/zram-generator.conf
sudo systemctl restart systemd-zram-setup@zram0.service
```

**What it does:**
- `zram-size = ram / 2` — Creates zRAM device at 50% of physical RAM
- `compression-algorithm = zstd` — Uses Zstandard (modern, fast compression)

**Check status:**
```bash
zramctl
journalctl -u systemd-zram-setup@zram0.service -n 20
```

---

## journald — Log Size Limits

Keeps systemd journal from consuming unlimited disk space.

### journald/size.conf
Size and retention policy for persistent journal storage:

```bash
sudo cp system/journald/size.conf /etc/systemd/journald.conf.d/
sudo systemctl restart systemd-journald
```

**What it does:**
- `SystemMaxUse=500M` — Journal never exceeds 500 MB
- `MaxRetentionSec=1month` — Purge logs older than 1 month

**Check current usage:**
```bash
journalctl --disk-usage
journalctl --vacuum-time=1month  # Manual cleanup if needed
```

---

## earlyoom — OOM Prevention

Kills memory hogs before kernel OOM killer triggers, preventing system freeze.

### earlyoom/earlyoom
Configuration for earlyoom daemon:

```bash
sudo cp system/earlyoom/earlyoom /etc/default/
sudo systemctl restart earlyoom
```

**What it does:**
- `-r 0` — No reboot on OOM (kill process instead)
- `-m 15,5` — Kill when memory is 15% free; second kill at 5%
- `-s 15,5` — Same swap threshold (15%, 5%)
- `-n` — Use notification for kill (no prompt)
- `--avoid <pattern>` — Whitelist critical processes (session managers, init, display servers, etc.)

**Check status:**
```bash
sudo systemctl status earlyoom
sudo systemctl enable earlyoom  # Auto-start on boot
journalctl -u earlyoom -n 20   # View recent activity
```

---

## Applying All At Once

For fresh machine setup:

```bash
# Memory & Network
sudo cp system/sysctl/*.conf /etc/sysctl.d/
sudo sysctl --system

# zRAM
sudo cp system/zram/zram-generator.conf /etc/systemd/zram-generator.conf
sudo systemctl restart systemd-zram-setup@zram0.service

# Journald
sudo cp system/journald/size.conf /etc/systemd/journald.conf.d/
sudo systemctl restart systemd-journald

# earlyoom (if installed)
if command -v earlyoom &>/dev/null; then
  sudo cp system/earlyoom/earlyoom /etc/default/
  sudo systemctl restart earlyoom
  sudo systemctl enable earlyoom
fi
```

---

## Safety Notes

- **Backup existing configs** before overwriting
- **Review each file** in Claude Code before applying
- **Kernel parameters** take effect immediately; most are non-destructive
- **earlyoom** kills processes — test with `sudo earlyoom --dryrun` first
- **Journal size** changes take effect on next log rotation

---

## Distro Notes

- These configurations were tested on **Fedora 43**
- BBR congestion control requires kernel 4.9+
- zRAM and systemd-zram-setup are standard on modern distributions
- earlyoom is available on Fedora, Debian, Arch, and derivatives
