#!/bin/bash
# Clawdbot ARM Compatibility Patch
# Run this after installing or updating Clawdbot on Raspberry Pi

set -e

PATCH_TARGET="$HOME/.npm-global/lib/node_modules/clawdbot/node_modules/@mariozechner/pi-coding-agent/dist/utils/clipboard-image.js"

if [ ! -f "$PATCH_TARGET" ]; then
    echo "Error: Target file not found at $PATCH_TARGET"
    echo "Make sure Clawdbot is installed: npm install -g clawdbot"
    exit 1
fi

# Backup original if no backup exists
if [ ! -f "${PATCH_TARGET}.backup" ]; then
    cp "$PATCH_TARGET" "${PATCH_TARGET}.backup"
    echo "Original file backed up to ${PATCH_TARGET}.backup"
fi

# Apply patch
cat > "$PATCH_TARGET" << 'EOF'
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

echo "✅ Clawdbot ARM patch applied successfully!"
echo ""
echo "Don't forget to set memory limits if you haven't:"
echo '  export NODE_OPTIONS="--max-old-space-size=512"'
