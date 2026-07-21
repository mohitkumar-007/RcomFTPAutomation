# Gameplay Test Suite — Team Checklist

**Goal:** Enable your entire team to run (or view) gameplay test results without confusion.

---

## For QA / Test Engineers (Who Run Tests)

### Before First Run (One Time)

- [ ] **Clone BOTH repos:**
  ```bash
  # App source code (Prism)
  git clone https://github.com/your-org/prism.git ~/Developer/prism
  
  # Test suite (RcomFTPAutomation)
  git clone https://github.com/your-org/RcomFTPAutomation.git ~/LearningMaterials/RcomFTPAutomation
  ```
- [ ] Install FVM: https://fvm.app/
  ```bash
  fvm install 3.41.6
  fvm use 3.41.6
  ```
- [ ] Install Android SDK (via Android Studio or `brew install android-sdk`)
- [ ] Install Patrol: `pub global activate patrol_cli 4.5.1`
- [ ] Install Allure CLI: `brew install allure` (or `apt-get`)
- [ ] Connect an Android device (USB) or start emulator (Android 13+, API 34)

**Verification (copy-paste these):**
```bash
flutter --version        # should show 3.41.6
patrol --version         # should show 4.5.1+
adb devices              # should list your device
allure --version         # should show 2.x.x
```

### Every Run

```bash
cd RcomFTPAutomation
./run_suite.sh
```

Report opens automatically in browser.

**Done.**

---

## For Stakeholders / DevOps / CI Admins (Who View Results)

### Setup (One Time)

No device needed. Just:

- [ ] GitHub account + access to your repo
- [ ] Install Allure CLI locally (optional — for re-hosting reports)
  ```bash
  brew install allure  # macOS
  ```

### Viewing Results

**Automatic daily runs:**
1. Go to GitHub repo → **Actions** tab
2. Click **Gameplay Test Suite** → latest run
3. Scroll to **Artifacts** → download `gameplay-test-results`
4. Unzip → open `allure-results/index.html` in browser

**Manual trigger:**
1. Go to GitHub repo → **Actions** tab
2. Click **Gameplay Test Suite** (left sidebar)
3. Click **Run workflow** (blue button) → **Run workflow**
4. Wait ~90 min → download Artifacts

---

## For Project Leads (Decision Makers)

### What's Now Automated?

✅ **Daily regression tests** — runs every night at 2 AM UTC (configurable)
✅ **Guest-only session** — no login loops, no data pollution
✅ **Fresh reports** — stakeholders always see today's results, not historical noise
✅ **Full scenario coverage** — all 6 test files × 2 player configs (2P + 6P) in one run
✅ **Known issues flagged** — 6P Drop & Leave chip-settlement bug clearly marked as "KNOWN ISSUE"

### Cost

$0 (GitHub Actions free tier covers ~150 run-hours/month)

### Timeline

- **Setup:** Already done ✅
- **First run:** Next push to `main` or manual trigger on GitHub Actions
- **Ongoing:** Automatic (daily at 2 AM) + on-demand

### Fallback

If GitHub Actions is down, any team member can run locally:
```bash
./run_suite.sh
# Results in 45–60 min
```

---

## Troubleshooting

**"Device not found"** → `adb devices` must list a device → plug in USB cable or start emulator

**"Flutter version wrong"** → `fvm use 3.41.6` then `flutter --version`

**"Allure report looks broken"** → Clear cache: `rm -rf reports/allure-results && ./generate_report.sh`

**"Test hangs on 6P"** → Expected behavior due to known app bug; watchdog catches it and flags as KNOWN ISSUE

See **TEAM_SETUP.md** for full troubleshooting.

---

## Docs Quick Links

| Role | Document |
|---|---|
| **QA Engineer** (runs tests) | [TEAM_SETUP.md](TEAM_SETUP.md) |
| **Stakeholder** (views reports) | This checklist + GitHub Artifacts |
| **DevOps/Admin** (sets up CI) | [DEVICE_OPTIONS.md](DEVICE_OPTIONS.md) |
| **Quick reference** | [QUICK_START.md](QUICK_START.md) |

---

## One-Time Instructions for Your Team

Send them this:

> **Gameplay tests are now automated!** 🎮
>
> **To run locally:**
> 1. Clone this repo
> 2. Follow [TEAM_SETUP.md](TEAM_SETUP.md)
> 3. Run: `cd RcomFTPAutomation && ./run_suite.sh`
>
> **To view results (no device needed):**
> 1. Go to Actions tab on GitHub
> 2. Click "Gameplay Test Suite" → latest run
> 3. Download the `gameplay-test-results` artifact
> 4. Open `allure-results/index.html` in browser
>
> **Questions?** See [QUICK_START.md](QUICK_START.md) or ping #qa-automation.

