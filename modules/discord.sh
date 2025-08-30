#!/bin/bash
#
# modules/discord
#
# Discord module for the dashboard.
#

FORMAT="$1"

case "$FORMAT" in
    plain)
        echo "Discord module coming soon..."
        ;;
    pretty)
        echo "Discord module coming soon..."
        ;;
    *)
        # Produce no output for other formats until implemented
        exit 0
        ;;
esac
