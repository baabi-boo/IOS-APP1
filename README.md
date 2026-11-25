<div align="center">

<img src="Dewy/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="128" alt="Dewy app icon" />

# Dewy — cute water tracker

**A tiny droplet buddy who gets happier with every sip.**
Log drinks, watch Dewy fill up, keep your streak, and grow a garden that blooms every day you hit your goal.

SwiftUI · iOS 17+ · Swift Charts · StoreKit 2 · no third-party dependencies

[![iOS build & screenshots](https://github.com/mirzotipi-wq/APP2/actions/workflows/ios.yml/badge.svg)](https://github.com/mirzotipi-wq/APP2/actions/workflows/ios.yml)

<img src="docs/demo.gif" width="300" alt="Dewy filling up and celebrating the daily goal" />

</div>

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/01-today.png" width="240" alt="Today" />
  <img src="docs/screenshots/02-add-drink.png" width="240" alt="Add a drink" />
  <img src="docs/screenshots/03-insights.png" width="240" alt="Insights" />
</p>
<p align="center">
  <img src="docs/screenshots/04-garden.png" width="240" alt="Dew Garden" />
  <img src="docs/screenshots/05-paywall.png" width="240" alt="Dewy+ paywall" />
  <img src="docs/screenshots/06-settings.png" width="240" alt="Settings" />
</p>
<p align="center">
  <img src="docs/screenshots/07-welcome.png" width="240" alt="Onboarding: Meet Dewy" />
  <img src="docs/screenshots/08-goal.png" width="240" alt="Onboarding: daily goal" />
  <img src="docs/screenshots/12-midnight.png" width="240" alt="Midnight theme" />
</p>

<details>
<summary><b>More themes</b> (Peachy · Matcha · Lavender)</summary>
<p align="center">
  <img src="docs/screenshots/09-peach.png" width="240" alt="Peachy theme" />
  <img src="docs/screenshots/10-matcha.png" width="240" alt="Matcha theme" />
  <img src="docs/screenshots/11-lavender.png" width="240" alt="Lavender theme" />
</p>
</details>

> Every screenshot above is a real iOS Simulator capture, taken by CI on each push (`.github/workflows/ios.yml` → `scripts/screenshots.sh`). The GIF comes from the simulator recording in `docs/raw/`. CI simulators have no GPU, so the GIF plays less smoothly than the app does on a real iPhone.

---

## Why this app?

**People already pay for this.** Water tracking is one of the most searched-for habits in Health & Fitness, and the *cute* version of it sells well:

| App | Angle | Third-party revenue estimate |
| --- | --- | --- |
| Waterllama | Cute characters + water tracking | ~$90K–160K / month (estimates vary, some much higher) |
| Finch | Cute pet that grows as you build habits | ~$1M / month |

Those numbers come from analytics sites (Screensdesign, Adapty, AppGoblin), so treat them as rough. What they show is that a **cute mascot plus a simple daily habit** keeps people coming back and paying.

**Why $1K/month is realistic.** The goal is ~$1K/month, not millions. At $19.99/year, that's about **50–60 new yearly subscribers a month**. With a typical 2–4% download-to-paid conversion, that takes roughly **1,500–3,000 downloads a month** (≈50–100 a day). A well-made niche app with good App Store optimization (ASO) can reach that.

**Why it's easy to build.** One screen does most of the work, all data stays on the device (no backend, no accounts), and the code is about 4K lines of SwiftUI.

## Features

- 💧 **Dewy, a living mascot.** A droplet with animated waves, rising bubbles, blinking eyes and four moods (thirsty → okay → happy → ecstatic). It squishes when you drink and wobbles when you poke it.
- ⚡️ **One-tap logging.** Sip / Glass / Bottle buttons, plus a drink sheet with an animated cup, slider and presets.
- 🍵 **8 drinks with hydration factors.** Coffee counts as 80%, soda as 60%, and so on.
- 🎉 **Goal celebration.** A confetti, heart and droplet burst with haptics when you hit 100%.
- 📈 **Insights.** Swift Charts bar chart with a goal line, a donut chart of what you drink, an hourly "sip rhythm", streaks and hit rate.
- 🌸 **Dew Garden.** Every day you hit your goal grows a swaying flower. Garden levels and 9 collectible badges.
- 🔔 **Gentle reminders.** Local notifications between wake-up and bedtime, with rotating cute messages.
- 🎨 **5 themes.** Lagoon (free), plus Peachy, Matcha, Lavender and a dark Midnight theme.
- 🧭 **Personalized onboarding.** Weight, activity, climate and schedule set your daily goal, revealed with a counting animation.
- 🔒 **Private by design.** Everything is stored on the device in a single JSON file.

## Monetization (Dewy+)

StoreKit 2, implemented in `PurchaseManager.swift`:

| Product ID | Type | Price |
| --- | --- | --- |
| `dewy.plus.yearly` | Auto-renewable, 3-day free trial | $19.99 / year |
| `dewy.plus.monthly` | Auto-renewable | $2.99 / month |
| `dewy.plus.lifetime` | Non-consumable | $39.99 |

**Free:** core tracking, Lagoon theme, water/tea/coffee/juice, 7-day insights, garden and badges.
**Dewy+:** 4 premium themes, sparkling/milk/smoothie/soda, 30-day insights, and custom reminder intervals.

`Dewy.storekit` is wired into the shared scheme, so purchases work in the simulator with no App Store Connect setup.

## Project structure

```
Dewy/
├── App/DewyApp.swift            # entry point, root routing, floating tab bar
├── Design/                      # themes, colors, typography, glass cards, buttons, haptics
├── Components/                  # MascotView (Dewy), shapes, waves, confetti, background, flowers
├── Models/Models.swift          # drinks, profile, achievements, tips
├── Store/                       # HydrationStore (state + stats), StoreKit, reminders, demo data
└── Features/                    # Today, Drink picker, Insights, Garden, Settings, Paywall, Onboarding
Dewy.xcodeproj                   # Xcode 16 project (folder-synced; new files are picked up automatically)
Dewy.storekit                    # local StoreKit testing config
scripts/screenshots.sh           # builds and captures simulator screenshots
```

## Build & run

1. Open `Dewy.xcodeproj` in **Xcode 16 or later**.
2. Choose your team under *Signing & Capabilities* and change the bundle ID (`com.dewyapp.Dewy`).
3. Run on an iPhone or simulator running iOS 17+.

**Demo mode.** Launch with `-screenshot today|add|insights|garden|settings|paywall|onboarding|celebrate` to load sample data. Optional flags: `-theme peach`, `-premium YES`, `-step 0…5`. Run `bash scripts/screenshots.sh` to regenerate every screenshot.

## Shipping checklist

- [ ] Set your bundle ID and team, and create the 3 products above in App Store Connect.
- [ ] Replace the Terms and Privacy links in `PaywallView.swift` with your own.
- [ ] App Store title idea: **"Dewy: Cute Water Tracker"**. Subtitle: *"Drink reminder & hydration pet"*.
- [ ] Keywords: `water,reminder,hydration,drink,tracker,intake,habit,cute,pet,daily,goal,log`.
- [ ] Post short TikTok/Reels clips of Dewy celebrating. Cute mascots spread well on short-video apps.

## Roadmap ideas

- Home and Lock Screen widgets (most-requested feature for water apps)
- Apple Health water sync
- Live Activity and Apple Watch quick-log
- More mascot outfits as rewards
