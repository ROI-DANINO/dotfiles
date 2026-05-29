#!/bin/bash
# Battery module for Waybar — TLP-aware charge limit display

BATTERY_PATH="/sys/class/power_supply/BAT0"
[ ! -d "$BATTERY_PATH" ] && BATTERY_PATH="/sys/class/power_supply/BAT1"

CAPACITY=$(cat "$BATTERY_PATH/capacity"       2>/dev/null || echo "0")
STATUS=$(cat   "$BATTERY_PATH/status"         2>/dev/null || echo "Unknown")
CHARGE_LIMIT=$(cat "$BATTERY_PATH/charge_control_end_threshold" 2>/dev/null || echo "100")

# Icon selection
if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
    if   [ "$CAPACITY" -ge 80 ]; then ICON=" "
    elif [ "$CAPACITY" -ge 60 ]; then ICON=" "
    elif [ "$CAPACITY" -ge 40 ]; then ICON=" "
    elif [ "$CAPACITY" -ge 20 ]; then ICON=" "
    else                               ICON=" "
    fi
else
    if   [ "$CAPACITY" -ge 80 ]; then ICON=" "
    elif [ "$CAPACITY" -ge 60 ]; then ICON=" "
    elif [ "$CAPACITY" -ge 40 ]; then ICON=" "
    elif [ "$CAPACITY" -ge 20 ]; then ICON=" "
    else                               ICON=" "
    fi
fi

# TLP charge limit active when threshold < 100
TLP_ACTIVE=false
[ "$CHARGE_LIMIT" -lt 100 ] 2>/dev/null && TLP_ACTIVE=true

if $TLP_ACTIVE && { [ "$STATUS" = "Not charging" ] || [ "$STATUS" = "Full" ]; } \
   && [ "$CAPACITY" -ge "$((CHARGE_LIMIT - 2))" ]; then
    # Sitting at the TLP cap
    DISPLAY_TEXT="${ICON} ${CAPACITY}% "
    CLASS="health-limit"
    TOOLTIP="Battery: ${CAPACITY}%\\nStatus: Capped by TLP (limit: ${CHARGE_LIMIT}%)"
elif [ "$STATUS" = "Charging" ]; then
    DISPLAY_TEXT="${ICON} ${CAPACITY}% "
    CLASS="charging"
    if $TLP_ACTIVE; then
        TOOLTIP="Battery: ${CAPACITY}%\\nStatus: Charging (TLP limit: ${CHARGE_LIMIT}%)"
    else
        TOOLTIP="Battery: ${CAPACITY}%\\nStatus: Charging"
    fi
elif [ "$STATUS" = "Full" ]; then
    DISPLAY_TEXT="  100%"
    CLASS="good"
    TOOLTIP="Battery: Full"
elif [ "$CAPACITY" -le 20 ]; then
    DISPLAY_TEXT="${ICON} ${CAPACITY}%"
    CLASS="critical"
    TOOLTIP="Battery: ${CAPACITY}%\\nStatus: Low Battery!"
elif [ "$CAPACITY" -le 40 ]; then
    DISPLAY_TEXT="${ICON} ${CAPACITY}%"
    CLASS="warning"
    TOOLTIP="Battery: ${CAPACITY}%\\nStatus: ${STATUS}"
else
    DISPLAY_TEXT="${ICON} ${CAPACITY}%"
    CLASS="good"
    TOOLTIP="Battery: ${CAPACITY}%\\nStatus: ${STATUS}"
fi

printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
    "$DISPLAY_TEXT" "$CLASS" "$TOOLTIP"
