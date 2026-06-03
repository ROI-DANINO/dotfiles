# Power Management

## Power Management

TLP manages battery charge threshold. Configuration lives in `/etc/tlp.conf` (system file, not in this repo).

```ini
STOP_CHARGE_THRESH_BAT0=85
```

The 85% cap is intentional for Zenbook/ASUS battery longevity. Do not suggest raising it.

Waybar `battery.sh` reads the threshold dynamically from:
```
/sys/class/power_supply/BAT0/charge_control_end_threshold
```

It applies CSS class `health-limit` when the battery is sitting at the TLP cap (not a fault state).

**Removed**: `auto-cpufreq` git-based daemon (fully replaced by TLP as of 2026-05-30). Do not suggest reinstalling it.
