[ "$INTERFACE" = wan ] || exit 0
[ "$ACTION" = ifup -o "$ACTION" = ifdown ] || exit 0

[ -z "$(uci -q get asterisk.terastream.server)" ] && exit 0

PIDFILE=/var/run/terastream-hack.pid
SCRIPT=/usr/bin/terastream-sip-hack.sh

[ "$ACTION" = ifup ] && [ ! -f $PIDFILE ] && {
    start-stop-daemon -S -b -m -p $PIDFILE -x $SCRIPT
}

[ "$ACTION" = ifdown ] && {
    start-stop-daemon -K -p $PIDFILE
    rm -f -- "$PIDFILE"
}

