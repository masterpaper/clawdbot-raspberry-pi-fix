#!/bin/bash
# Clawdbot Watchdog - Monitors and auto-restarts clawdbot if crashed

LOCK_FILE="/tmp/clawdbot-manual-stop.lock"
LOG_FILE="/tmp/clawdbot-watchdog.log"
CHECK_INTERVAL=30

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

is_running() {
    pgrep -u clawd -f "clawdbot" > /dev/null 2>&1
}

restart_clawd() {
    log "Starting Clawdbot..."
    sudo -u clawd bash -c 'cd /home/clawd && nohup /home/clawd/.npm-global/bin/clawdbot gateway run > /home/clawd/.clawdbot/gateway.log 2>&1 &'
    sleep 3
    if is_running; then
        log "✓ Clawdbot restarted successfully"
        return 0
    else
        log "✗ Failed to restart Clawdbot"
        return 1
    fi
}

case "$1" in
    monitor)
        log "=== Watchdog started (PID $$) ==="
        log "Checking every ${CHECK_INTERVAL}s. Lock file: $LOCK_FILE"
        
        while true; do
            sleep "$CHECK_INTERVAL"
            
            if ! is_running; then
                if [ -f "$LOCK_FILE" ]; then
                    # Manual stop - don't restart
                    :
                else
                    log "! Clawdbot crashed - restarting..."
                    restart_clawd
                fi
            fi
        done
        ;;
    check)
        # One-shot check (for cron if preferred)
        if ! is_running; then
            if [ -f "$LOCK_FILE" ]; then
                log "Clawdbot down but manually stopped - not restarting"
            else
                log "Clawdbot crashed - restarting..."
                restart_clawd
            fi
        fi
        ;;
    *)
        echo "Clawdbot Watchdog"
        echo "Usage: $0 {monitor|check}"
        echo ""
        echo "  monitor - Run continuously (for 'start dog')"
        echo "  check   - One-shot check (for cron)"
        ;;
esac
