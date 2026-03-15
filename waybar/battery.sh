#!/bin/bash
# Battery module for Waybar
# Supports ASUS battery health charging (75% limit)

BATTERY_PATH="/sys/class/power_supply/BAT0"
ADAPTER_PATH="/sys/class/power_supply/ACAD"

# Fallback paths for different ASUS models
if [ ! -d "$BATTERY_PATH" ]; then
    BATTERY_PATH="/sys/class/power_supply/BAT1"
fi
if [ ! -d "$ADAPTER_PATH" ]; then
    ADAPTER_PATH="/sys/class/power_supply/AC"
fi

# Get basic battery info
CAPACITY=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "0")
STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")

# Check ASUS battery health charging status (75% limit)
# asusctl stores the mode in /sys/firmware/asus-linux/
HEALTH_MODE=""
if command -v asusctl &>/dev/null; then
    ASUS_MODE=$(asusctl battery --print-mode 2>/dev/null | grep -oP '(?<=Battery current state:\s).*' || echo "")
    case "$ASUS_MODE" in
        "Maximum"*|"Maximum")
            HEALTH_MODE="max"
            ;;
        "Balanced"*|"Balanced")
            HEALTH_MODE="balanced"
            ;;
        "Quiet"*|"Quiet")
            HEALTH_MODE="quiet"
            ;;
    esac
fi

# Alternative: check via sysfs for ASUS health charging
HEALTH_CHARGING=""
if [ -f "/sys/firmware/asus-linux/battery_mode" ]; then
    HEALTH_CHARGING=$(cat /sys/firmware/asus-linux/battery_mode 2>/dev/null)
fi

# Determine icon
ICON=" "
CHARGING_ICON=" "

if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
    if [ "$CAPACITY" -ge 80 ]; then
        ICON=" "
    elif [ "$CAPACITY" -ge 60 ]; then
        ICON=" "
    elif [ "$CAPACITY" -ge 40 ]; then
        ICON=" "
    elif [ "$CAPACITY" -ge 20 ]; then
        ICON=" "
    else
        ICON=" "
    fi
else
    if [ "$CAPACITY" -ge 80 ]; then
        ICON=" "
    elif [ "$CAPACITY" -ge 60 ]; then
        ICON=" "
    elif [ "$CAPACITY" -ge 40 ]; then
        ICON=" "
    elif [ "$CAPACITY" -ge 20 ]; then
        ICON=" "
    else
        ICON=" "
    fi
fi

# Build display text
if [ -n "$HEALTH_MODE" ] || [ "$HEALTH_CHARGING" = "1" ]; then
    # Health limit active (75% mode)
    DISPLAY_TEXT="${ICON} ${CAPACITY}% "
    CLASS="health-limit"
    TOOLTIP="Battery: ${CAPACITY}%\nStatus: Health Mode (75% Limit)\nMode: ${ASUS_MODE:-Balanced}"
elif [ "$STATUS" = "Charging" ]; then
    DISPLAY_TEXT="${ICON} ${CAPACITY}% "
    CLASS="charging"
    TOOLTIP="Battery: ${CAPACITY}%\nStatus: Charging"
elif [ "$STATUS" = "Full" ]; then
    DISPLAY_TEXT="  100%"
    CLASS="good"
    TOOLTIP="Battery: Full"
elif [ "$CAPACITY" -le 20 ]; then
    DISPLAY_TEXT="${ICON} ${CAPACITY}%"
    CLASS="critical"
    TOOLTIP="Battery: ${CAPACITY}%\nStatus: Low Battery!"
elif [ "$CAPACITY" -le 40 ]; then
    DISPLAY_TEXT="${ICON} ${CAPACITY}%"
    CLASS="warning"
    TOOLTIP="Battery: ${CAPACITY}%\nStatus: ${STATUS}"
else
    DISPLAY_TEXT="${ICON} ${CAPACITY}%"
    CLASS="good"
    TOOLTIP="Battery: ${CAPACITY}%\nStatus: ${STATUS}"
fi

# Output JSON for Waybar
printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$DISPLAY_TEXT" "$CLASS" "$TOOLTIP"