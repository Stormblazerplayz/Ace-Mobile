# Ace V4 for iPad

Ace is a little glowing orb that lives on your iPad. It answers questions, keeps your Nimbus calendar, sets timers and reminders, looks things up on the web, and wakes up every 15 to 30 minutes to look around (two digital eyes pop out) and check that everything's okay.

It runs on the iPad all by itself. PC sync with Nimbus is planned and stays off by default.

## What works in this version

- **Orb island:** the orb sits at the top. When Ace checks things it stretches into a pill and two eyes look around. It also shows typing, thinking, talking, alert and happy moods.
- **Ace V4 brain:** rules, a bank of 2,407 answers (7,690 ways to ask), Apple's on-device neural sentence matcher, a small intent classifier, math, unit conversion, dates, and web research with short summaries. You can see how it got each answer under "How I got this". It learns when you teach it ("no, the answer is ...").
- **Nimbus calendar:** Ace makes a calendar called Nimbus first. It adds, changes, and deletes events only after you tap Yes.
- **Checks:** battery, storage, memory, temperature, Wi-Fi, time, how long you've been away, what's next on your calendar, reminders, and Ace's own notifications. Tap the orb to check now.
- **Daily greeting, bedtime tips, timers, reminders, recipes (with a checklist card), weather (7 days), and opening sites in an in-app browser tab.**
- **Sounds and haptics:** made just for Ace, panned left and right as the eyes look around.
- **Widgets:** Home Screen (small, medium) and Lock Screen (circle, rectangle, inline).
- **Pictures and camera:** tap + to pick a photo or take one. Ace reads what's in it, any text, QR codes and faces with Apple's Vision, all on the iPad.
- **On-device AI (off by default):** turn on LFM3 Omni in Settings > On-device AI and download it (about 1.6 GB, from Liquid AI on Hugging Face). It runs with llama.cpp, which the GitHub build adds automatically. Apple Intelligence wording is a second switch for iPadOS 26. Ace's own brain always answers first. The model helps with wording, questions Ace doesn't know, and questions about pictures.

## Coming next

Pictures straight into LFM3 Omni, screenshot and file search, hands-free voice, and PC sync with Nimbus.

## Things iPadOS doesn't let an app do

Ace can't close, resize, or minimize other apps, read other apps' notifications, or see what's on your screen. When you ask, Ace says so and offers what it can do. When Ace is closed, iPadOS decides when it may wake up, so background checks can be less often than every 15 to 30 minutes.

## Build it

The Xcode project is made from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open Ace.xcodeproj
```

To build with the LFM3 Omni engine on your Mac, put `llama.xcframework` from the newest [llama.cpp release](https://github.com/ggml-org/llama.cpp/releases) in `Vendor/`, then run `python3 tools/make_llama_spec.py` and `xcodegen generate --spec project-llama.yml`.

## TestFlight (same setup as Squall-mobile)

Every push and pull request builds the app on GitHub (`.github/workflows/ios.yml`). Pushes to `main` also sign it and send it to TestFlight once these repository secrets are set (Settings > Secrets and variables > Actions), the same ones Squall uses:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_P8` (the whole .p8 file)
- `APPLE_TEAM_ID`

In App Store Connect, make an app with bundle id `com.stormblazerplayz.ace`. The widget uses `com.stormblazerplayz.ace.widgets`, which Xcode registers automatically with the API key. Never put the key in the code. `.gitignore` blocks `.p8`, `.p12` and provisioning files.

## Answer bank

`Ace/Resources/qa_bank.json` uses the `ace-qa/1` format that Ace V4 on the PC also reads (see `docs/qa-format.md`). Rebuild it with:

```bash
python3 tools/build_qa_bank.py
```

Sounds and the icon come from `tools/make_sounds.py` and `tools/make_icon.py`.
