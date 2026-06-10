# Auto-start niri on TTY1 login
if [[ -z $DISPLAY && -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]; then
    exec niri-session
fi
