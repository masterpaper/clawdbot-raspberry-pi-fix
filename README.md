# Clawdbot Raspberry Pi (ARM) Compatibility Fix

This repository documents how to get [Clawdbot](https://github.com/clawdbot/clawdbot) running on Raspberry Pi devices with ARM architecture (specifically tested on Raspberry Pi 3B).

> **⚠️ [Read the Disclaimer](DISCLAIMER.md)** — Pros, cons, and what to expect when running an AI agent on a Pi.

## The Problem

When installing Clawdbot on a Raspberry Pi, you'll encounter a fatal error because the `@mariozechner/clipboard` module doesn't have a pre-built native binary for ARM (specifically `linux-arm-gnueabihf`).

### Error Messages You'll See

When running `clawdbot gateway start` or similar commands, you'll get:

```
Error: Cannot find module '@anthropic-ai/claude-code'
```

And deeper in the stack trace:

```
Error: Cannot find module '@mariozechner/clipboard-linux-arm-gnueabihf'
Require stack:
- /home/clawd/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/clipboard/index.js
- /home/clawd/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/pi-coding-agent/dist/utils/clipboard-image.js
```

The root cause: The clipboard module expects a platform-specific binary that doesn't exist for 32-bit ARM Linux.

## The Solution

We patch the clipboard import to make it optional — wrapping it in a try-catch so Clawdbot can still run even without clipboard functionality.

---

## Full Installation Guide for Raspberry Pi 3B

### Prerequisites

- Raspberry Pi 3B (or similar ARM device)
- Raspberry Pi OS (32-bit)
- Node.js v22.x
- At least 1GB of RAM (with swap enabled recommended)

### Step 1: Install Node.js v22

The default Node.js in Raspberry Pi OS repos is outdated. Install v22:

```bash
# Remove old Node.js if present
sudo apt remove nodejs npm -y

# Add NodeSource repo for Node 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -

# Install Node.js
sudo apt install nodejs -y

# Verify installation
node --version  # Should show v22.x.x
npm --version
```

### Step 2: Configure npm Global Directory

Avoid permission issues by using a user-owned global directory:

```bash
# Create directory for global packages
mkdir -p ~/.npm-global

# Configure npm to use it
npm config set prefix '~/.npm-global'

# Add to PATH (add this to ~/.bashrc for persistence)
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Step 3: Install Clawdbot

```bash
npm install -g clawdbot
```

This will partially fail due to the ARM binary issue — that's expected!

### Step 4: Apply the ARM Compatibility Patch

This is the key fix. We modify the clipboard import to be optional:

```bash
# Navigate to the problematic file
cd ~/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/pi-coding-agent/dist/utils

# Backup the original file
cp clipboard-image.js clipboard-image.js.backup

# View the original import (for reference)
head -5 clipboard-image.js
```

The original file starts with:
```javascript
import clipboard from "@anthropic-ai/claude-code/vendor/@anthropic-ai/clipboard";
```

**Replace the entire file content** with this patched version:

```bash
cat > clipboard-image.js << 'EOF'
// Patched for ARM compatibility - clipboard is optional
let clipboard = null;
try {
    clipboard = await import("@anthropic-ai/claude-code/vendor/@anthropic-ai/clipboard");
    clipboard = clipboard.default || clipboard;
} catch (e) {
    console.warn("[clipboard-image] Clipboard module not available on this platform - clipboard features disabled");
}

export async function getClipboardImage() {
    if (!clipboard) {
        return null;
    }
    try {
        const result = clipboard.readImage();
        if (result && result.length > 0) {
            return result;
        }
        return null;
    } catch (e) {
        return null;
    }
}
EOF
```

### Step 5: Configure Memory Limits

Raspberry Pi 3B has limited RAM. The Clawdbot gateway needs a memory cap to avoid crashes:

```bash
# Add to ~/.bashrc for persistence
echo 'export NODE_OPTIONS="--max-old-space-size=512"' >> ~/.bashrc
source ~/.bashrc
```

This limits Node.js heap to 512MB, leaving room for the OS and other processes.

### Step 6: Initialize Clawdbot

```bash
# Create a workspace directory
mkdir -p ~/clawd
cd ~/clawd

# Initialize Clawdbot
clawdbot init
```

Follow the prompts to:
- Add your Anthropic API key
- Configure channels (webchat, Telegram, etc.)

### Step 7: Start the Gateway

```bash
# Start the gateway daemon
clawdbot gateway start

# Check status
clawdbot status
```

---

## Accessing the Web UI Remotely

The Clawdbot web UI runs on `localhost:3577` by default. To access it from another computer, use SSH tunneling:

### From your local machine (Mac/Linux/Windows with SSH):

```bash
ssh -L 3577:localhost:3577 pi@<raspberry-pi-ip>
```

Replace `<raspberry-pi-ip>` with your Pi's local IP address (find it with `hostname -I` on the Pi).

Then open your browser to: **http://localhost:3577**

### Making it persistent

Add to your `~/.ssh/config` on your local machine:

```
Host pi-clawdbot
    HostName <raspberry-pi-ip>
    User pi
    LocalForward 3577 localhost:3577
```

Then just run `ssh pi-clawdbot` and the tunnel is automatic.

---

## Quick Reference: The Patch

If you need to reapply after updates, here's the one-liner:

```bash
cat > ~/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/pi-coding-agent/dist/utils/clipboard-image.js << 'EOF'
// Patched for ARM compatibility - clipboard is optional
let clipboard = null;
try {
    clipboard = await import("@anthropic-ai/claude-code/vendor/@anthropic-ai/clipboard");
    clipboard = clipboard.default || clipboard;
} catch (e) {
    console.warn("[clipboard-image] Clipboard module not available on this platform - clipboard features disabled");
}

export async function getClipboardImage() {
    if (!clipboard) {
        return null;
    }
    try {
        const result = clipboard.readImage();
        if (result && result.length > 0) {
            return result;
        }
        return null;
    } catch (e) {
        return null;
    }
}
EOF
```

---

## Troubleshooting

### "JavaScript heap out of memory"

Increase or decrease the memory limit based on your Pi model:

```bash
# For Pi 3B (1GB RAM)
export NODE_OPTIONS="--max-old-space-size=512"

# For Pi 4 (2GB+ RAM)
export NODE_OPTIONS="--max-old-space-size=1024"
```

### Gateway crashes on startup

1. Check logs: `clawdbot gateway logs`
2. Verify the patch was applied: `head -10 ~/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/pi-coding-agent/dist/utils/clipboard-image.js`
3. Make sure NODE_OPTIONS is set: `echo $NODE_OPTIONS`

### Patch gets overwritten after update

After running `npm update -g clawdbot`, you'll need to reapply the patch. Consider creating a shell script:

```bash
#!/bin/bash
# ~/fix-clawdbot-arm.sh
cat > ~/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/pi-coding-agent/dist/utils/clipboard-image.js << 'EOF'
// Patched for ARM compatibility - clipboard is optional
let clipboard = null;
try {
    clipboard = await import("@anthropic-ai/claude-code/vendor/@anthropic-ai/clipboard");
    clipboard = clipboard.default || clipboard;
} catch (e) {
    console.warn("[clipboard-image] Clipboard module not available on this platform - clipboard features disabled");
}

export async function getClipboardImage() {
    if (!clipboard) {
        return null;
    }
    try {
        const result = clipboard.readImage();
        if (result && result.length > 0) {
            return result;
        }
        return null;
    } catch (e) {
        return null;
    }
}
EOF
echo "Clawdbot ARM patch applied!"
```

Make it executable: `chmod +x ~/fix-clawdbot-arm.sh`

---

## Tested On

- **Device:** Raspberry Pi 3B
- **OS:** Raspberry Pi OS (32-bit, Bullseye)
- **Node.js:** v22.15.0
- **Clawdbot:** Latest as of January 2026

---

## Contributing

If you've tested this on other ARM devices or found improvements, please open an issue or PR!

## License

MIT — do whatever you want with this.

---

*Created by the Nadelberg household after getting Clawdbot running on a Pi 3B 🧑‍🚀*
