# 💊 PharmaPath — B.Pharm Exam Companion

**Sem 1 se Sem 8 tak — pura B.Pharm, simple bilingual notes.**
A complete 8-semester exam-prep app design system for B.Pharmacy students of
**Rajasthan University of Health Sciences (RUHS)** / PCI-pattern universities,
built for **Hindi-medium students** who need complex concepts in simple,
point-wise English + Hinglish.

> ⚠️ **Note:** This repository is the **design + prototype + data foundation**.
> The production app is built on a no-code platform (Glide → FlutterFlow) using
> the spec in `docs/`. See [docs/BPharm_App_Design_Spec.html](docs/BPharm_App_Design_Spec.html).

---

## 📦 What's inside

```
pharmapath/
├── app/                      # The app frontend (works fully OFFLINE)
│   ├── index.html            # Interactive clickable prototype (16 screens)
│   ├── manifest.webmanifest  # PWA install support (Add to Home Screen)
│   ├── sw.js                 # Service worker (offline caching)
│   └── icon-192/512.png      # App icons
├── android/                  # Android APK source (WebView wrapper)
│   ├── src/…/MainActivity.java
│   ├── AndroidManifest.xml
│   ├── res/                  # Launcher icons
│   └── build_apk.sh          # Reproduce the APK build
├── releases/
│   └── PharmaPath.apk        # ✅ Ready-to-install Android APK (v1.0)
├── data/
│   └── BPharm_Data_Starter.xlsx   # 17-table starter database (Google Sheets-ready)
├── database/
│   └── schema.sql            # Full PostgreSQL/Supabase schema + seed data
├── docs/
│   └── BPharm_App_Design_Spec.html  # THE full spec: 12 sections
│                                    # screens · schema · AI scanner prompts ·
│                                    # no-code build plan (Glide/Make/OpenAI)
└── LICENSE                   # MIT
```

---

## 🚀 4 ways to use this right now

### 1. Install the Android APK (fastest)
- Download [`releases/PharmaPath.apk`](releases/PharmaPath.apk)
- Copy it to your phone → tap it → allow "Install unknown apps"
- It's the **full interactive prototype** (dashboard → semesters → notes →
  bilingual toggle → scanner → premium), works **100% offline**, no internet needed.

### 2. Run the prototype in a browser
Open `app/index.html` — clickable demo of all 16 screens.

### 3. Install as a PWA (Android/Chrome)
Host the `app/` folder on any static host (GitHub Pages, Netlify, Vercel) →
open the URL → browser menu → **"Add to Home screen"** → it behaves like an app.

### 4. Build the real app (production path — no code)
Follow **Section 8** of the spec — 10 phases, Glide + Google Sheets + Make.com + OpenAI:
1. Upload `data/BPharm_Data_Starter.xlsx` to Google Sheets
2. Connect it to a new Glide app
3. Build screens per the spec, wire the AI Scanner (prompts are copy-paste ready)
4. Add Razorpay → launch on Play Store

---

## 🧠 Key design features (from the spec)

| Feature | Where |
|---|---|
| Sem 1→8 dashboard, subject modules, 3 tracks (Foundation / Core / Advanced) | `docs/…html` §3–4 |
| Point-wise notes (JSON arrays — paragraphs impossible) + flowcharts | §7, §10 |
| EN ⇄ Hinglish ⇄ हिंदी toggle (instant, offline, pre-stored) | §5 |
| **Smart Screenshot Scanner with STRICT rule** — *"Jo di hui vo drug hee, not think your side"* — 3-layer enforcement (extraction prompt + generation prompt + validation pass) | §6 |
| Premium Vault, Razorpay, entitlements | §11 |
| RUHS 70-mark paper alignment, PYQs 2019–2024 | §9 |

---

## 🛠 Rebuilding the APK

```bash
# requires: JDK 11+, Android build-tools 34+, platform android-35
./android/build_apk.sh
# outputs: releases/PharmaPath.apk (signed with debug keystore)
```

---

## 🗺 Roadmap

- **V1 (6 weeks):** Glide + Sheets + Make.com + OpenAI · PWA + stores
- **V2:** FlutterFlow + Supabase rebuild · offline packs · quizzes · community
- **V3:** Other PCI universities · D.Pharm track · admin CMS

## 📜 License
MIT — use it, fork it, build your app. (Design & sample content are original;
verify official syllabus/exam patterns before publishing.)

---

*Made for the RUHS B.Pharm student community · v1.0 · Aug 2026*
