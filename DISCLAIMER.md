# ⚠️ Disclaimer: Running an AI Agent on a Raspberry Pi

Before you dive in, here's an honest look at what you're getting into.

---

## ✅ The Good

- **Low power, always-on** — A Pi sips ~5W vs a full PC. Great for a 24/7 assistant.
- **Cheap hardware** — You might already have a Pi collecting dust.
- **Fun project** — There's something satisfying about running an AI agent on a $35 computer.
- **Privacy** — Your assistant lives on your local network, not some cloud VM.

---

## ⚠️ The Trade-offs

- **Limited RAM** — Pi 3B has only 1GB. Even with a 512MB heap limit, it's tight. Expect occasional restarts.
- **Swap usage wears out SD cards** — Node.js will hit swap under load. SD cards have limited write cycles. This *will* shorten your card's lifespan. Consider:
  - Using a high-endurance SD card (made for dashcams/security cameras)
  - Moving swap to a USB drive
  - Accepting you'll replace the card eventually
- **Slower responses** — The Pi itself is fine, but memory pressure and swap can add latency.
- **Heat under load** — Sustained use can throttle the CPU. A heatsink or fan helps.
- **Not officially supported** — This is a community workaround. Updates may break things, and you'll need to reapply patches.

---

## 💡 Recommendations

- **Use a Pi 4 with 2GB+ RAM if possible** — Much more comfortable experience.
- **Monitor your system** — Set up temp/memory alerts (we have a script for this!).
- **Have backups** — Your SD card *will* die someday. Back up your config.
- **Set expectations** — This is a scrappy, hobbyist setup. It works, but it's not enterprise-grade.

---

## 🤷 Is It Worth It?

If you want a low-power, always-available AI assistant and you're okay with some jank — absolutely. If you need reliability and speed, consider running Clawdbot on beefier hardware.

We run ours on a Pi 3B daily. It works. It's fun. Just know what you're signing up for.

---

*— The Nadelberg household 🧑‍🚀*
