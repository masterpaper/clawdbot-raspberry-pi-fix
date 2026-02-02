#!/bin/bash
# Run this ONCE as pi to install clawd and watchdog commands

echo "Installing clawd + watchdog commands for pi user..."

# Copy watchdog script to a global location
sudo cp /home/clawd/clawd/scripts/clawdbot-watchdog.sh /usr/local/bin/clawdbot-watchdog
sudo chmod +x /usr/local/bin/clawdbot-watchdog

# Add commands to pi's bashrc
cat >> /home/pi/.bashrc << 'EOF'

# Clawdbot commands
start() {
    case "$1" in
        clawd)
            echo "Starting Clawdbot..."
            # Remove manual stop lock so watchdog can protect
            rm -f /tmp/clawdbot-manual-stop.lock
            sudo -u clawd bash -c 'cd /home/clawd && nohup /home/clawd/.npm-global/bin/clawdbot gateway run > /home/clawd/.clawdbot/gateway.log 2>&1 &'
            sleep 2
            if pgrep -u clawd -f "clawdbot" > /dev/null; then
                echo "✓ Clawdbot is running!"
            else
                echo "✗ Failed. Check: /home/clawd/.clawdbot/gateway.log"
            fi
            ;;
        dog)
            echo "Starting watchdog..."
            if pgrep -f "clawdbot-watchdog.*monitor" > /dev/null; then
                echo "✗ Watchdog already running"
            else
                rm -f /tmp/clawdbot-manual-stop.lock
                nohup /usr/local/bin/clawdbot-watchdog monitor > /tmp/clawdbot-watchdog.log 2>&1 &
                sleep 1
                if pgrep -f "clawdbot-watchdog.*monitor" > /dev/null; then
                    echo "✓ Watchdog is running! Will auto-restart clawd if it crashes."
                else
                    echo "✗ Failed to start watchdog"
                fi
            fi
            ;;
        *)
            echo "Usage: start clawd | start dog"
            ;;
    esac
}

stop() {
    case "$1" in
        clawd)
            echo "Stopping Clawdbot..."
            # Create lock so watchdog doesn't restart
            touch /tmp/clawdbot-manual-stop.lock
            sudo pkill -u clawd -f "clawdbot" 2>/dev/null
            sleep 1
            if pgrep -u clawd -f "clawdbot" > /dev/null; then
                sudo pkill -9 -u clawd -f "clawdbot"
            fi
            echo "✓ Clawdbot stopped (watchdog won't restart it)"
            ;;
        dog)
            echo "Stopping watchdog..."
            pkill -f "clawdbot-watchdog.*monitor" 2>/dev/null
            sleep 1
            if pgrep -f "clawdbot-watchdog.*monitor" > /dev/null; then
                pkill -9 -f "clawdbot-watchdog.*monitor"
            fi
            echo "✓ Watchdog stopped"
            ;;
        *)
            echo "Usage: stop clawd | stop dog"
            ;;
    esac
}

restart() {
    case "$1" in
        clawd)
            echo "Restarting Clawdbot..."
            rm -f /tmp/clawdbot-manual-stop.lock
            sudo pkill -u clawd -f "clawdbot" 2>/dev/null
            sleep 2
            sudo -u clawd bash -c 'cd /home/clawd && nohup /home/clawd/.npm-global/bin/clawdbot gateway run > /home/clawd/.clawdbot/gateway.log 2>&1 &'
            sleep 2
            if pgrep -u clawd -f "clawdbot" > /dev/null; then
                echo "✓ Clawdbot restarted!"
            else
                echo "✗ Failed. Check: /home/clawd/.clawdbot/gateway.log"
            fi
            ;;
        *)
            echo "Usage: restart clawd"
            ;;
    esac
}

status() {
    case "$1" in
        clawd)
            echo "=== Clawdbot Status ==="
            PROCS=$(pgrep -u clawd -fa "clawdbot" 2>/dev/null)
            if [ -n "$PROCS" ]; then
                echo "✓ Clawdbot is running"
                echo ""
                echo "Processes:"
                ps -u clawd -o pid,etime,cmd --no-headers | grep clawdbot | grep -v grep
                echo ""
                if [ -f /tmp/clawdbot-manual-stop.lock ]; then
                    echo "⚠ Manual stop lock exists (watchdog won't auto-restart)"
                fi
            else
                echo "✗ Clawdbot is NOT running"
                echo ""
                echo "No clawdbot processes found."
            fi
            ;;
        dog)
            echo "=== Watchdog Status ==="
            PROCS=$(pgrep -fa "clawdbot-watchdog.*monitor" 2>/dev/null)
            if [ -n "$PROCS" ]; then
                echo "✓ Watchdog is running"
                echo ""
                echo "Processes:"
                ps -o pid,etime,cmd --no-headers -p $(pgrep -f "clawdbot-watchdog.*monitor") 2>/dev/null
                echo ""
                echo "Log: /tmp/clawdbot-watchdog.log"
            else
                echo "✗ Watchdog is NOT running"
            fi
            ;;
        *)
            echo "Usage: status clawd | status dog"
            ;;
    esac
}
EOF

echo "✓ Done! Commands installed."
echo ""
echo "Now either:"
echo "  1. Log out and back in, OR"
echo "  2. Run: source ~/.bashrc"
echo ""
echo "Commands available:"
echo "  start clawd  / stop clawd  / restart clawd  / status clawd"
echo "  start dog    / stop dog    / status dog"
