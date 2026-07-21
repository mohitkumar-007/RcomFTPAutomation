# Quick Start — Run the Suite in 30 Seconds

## Setup (One Time)

**Clone both repos:**

```bash
git clone https://github.com/your-org/prism.git ~/Developer/prism
git clone https://github.com/your-org/RcomFTPAutomation.git ~/LearningMaterials/RcomFTPAutomation
```

Then follow [TEAM_SETUP.md](TEAM_SETUP.md) for FVM/Android/Patrol (10 min).

---

## Local (Your Machine)

```bash
cd ~/LearningMaterials/RcomFTPAutomation
./run_suite.sh
```

Done. Report opens in browser automatically.

**Note:** If you cloned `prism` to a non-standard path:
```bash
RUMMY_DIR=/my/path/to/prism/apps/rummy ./run_suite.sh
```

---

## CI/CD (Automated on GitHub)

Just **push to `main` or `develop`** — GitHub Actions runs it automatically.

View results: **GitHub repo → Actions tab → latest run → download artifacts**

---

## Manual CI Trigger (No Push)

Go to: **GitHub repo → Actions → Gameplay Test Suite → Run workflow**

---

## Troubleshoot in 10 Seconds

```bash
# Device connected?
adb devices

# FVM correct version?
flutter --version   # should show 3.41.6

# Patrol installed?
patrol --version    # should show 4.5.1+

# Allure available?
allure --version    # should show 2.x.x
```

If any are missing, see **TEAM_SETUP.md** for install steps.

---

## Report Location

After `./run_suite.sh`:
- **Browser:** Opens automatically
- **Files:** `RcomFTPAutomation/reports/allure-results/index.html`

Or re-open anytime:
```bash
allure serve RcomFTPAutomation/reports/allure-results/
```

---

## Device Requirement

- **Physical Android device** (USB-connected) OR
- **Emulator** (Android 13+, API 34)

**Note:** Tests require a real device or emulator with Google Play services (for guest login backend). BrowserStack alternatives (like Sauce Labs, TestProject) are not pre-configured; if your team uses one, you'd need to adapt `run_suite.sh` to deploy the APK there first.

