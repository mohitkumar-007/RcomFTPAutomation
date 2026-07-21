# Gameplay Test Suite — Team Setup & Execution Guide

This document covers everything your team needs to run the Patrol gameplay tests locally or via CI/CD.

---

## Table of Contents

1. [Local Execution (macOS/Linux)](#local-execution)
2. [CI/CD Execution (GitHub Actions)](#cicd-execution)
3. [Troubleshooting](#troubleshooting)

---

## Local Execution

### Repository Setup

You need **TWO repositories** cloned:

1. **RcomFTPAutomation** (test orchestration + reporting)
2. **Prism/apps/rummy** (the app being tested)

**Recommended directory structure:**

```
~/Developer/
├── prism/
│   └── apps/
│       └── rummy/          ← clone https://github.com/your-org/prism here
└── LearningMaterials/
    └── RcomFTPAutomation/  ← clone https://github.com/your-org/RcomFTPAutomation here
```

**Clone both:**

```bash
# App (Prism)
cd ~/Developer
git clone https://github.com/your-org/prism.git

# Tests (RcomFTPAutomation)
cd ~/LearningMaterials  # or wherever you want
git clone https://github.com/your-org/RcomFTPAutomation.git
```

**If you use a different path for Prism:**

The scripts will auto-detect the common paths, but if you clone Prism elsewhere, set the environment variable:

```bash
cd RcomFTPAutomation
RUMMY_DIR=/my/custom/path/to/prism/apps/rummy ./run_suite.sh
```

---

### Prerequisites (One-Time Setup)

#### 1. **Flutter & FVM**

The app requires Flutter **3.41.6** exactly. Use FVM to manage it:

```bash
# Install FVM (if not already)
# macOS:
brew install fvm
# Linux: see https://fvm.app/docs/getting_started/installation

# Verify installation
fvm --version

# Ensure 3.41.6 is cached
ls ~/fvm/versions/
# If you see "3.41.6", skip the next step.

# Fetch it (one-time, ~2GB):
fvm install 3.41.6

# Use it in this repo
cd <this-repo>
fvm use 3.41.6

# Verify:
flutter --version  # should show 3.41.6
```

#### 2. **Android SDK & Emulator/Device**

**Option A: Android Studio (GUI, recommended for first-time)**

- Download from https://developer.android.com/studio
- Install normally
- Open Tools → SDK Manager → ensure **API 34** is installed
- Accept all SDK licenses

**Option B: Command-line only**

```bash
# macOS:
brew install android-sdk

# Verify:
sdkmanager --version

# Install API 34:
sdkmanager "platforms;android-34" "build-tools;34.0.0" "system-images;android-34;google_apis;x86_64"

# Accept licenses:
sdkmanager --licenses  # type 'y' for each
```

**Verify ADB (works for both options):**

```bash
adb --version  # should show "Android Debug Bridge version"
```

#### 3. **Patrol CLI**

```bash
pub global activate patrol_cli 4.5.1
patrol --version  # should show 4.5.1+
```

#### 4. **Allure CLI** (for viewing reports)

```bash
# macOS:
brew install allure

# Linux (Ubuntu/Debian):
sudo apt-get install allure

# Verify:
allure --version  # should show 2.x.x
```

#### 5. **Rummy App Dependencies**

```bash
cd <repo>/apps/rummy
flutter pub get
```

### Running the Full Suite Locally

**Step 1: Connect an Android device or start an emulator**

```bash
# Physical device: plug in via USB
# List connected devices:
adb devices

# OR start emulator (if you have one):
# Open Android Studio → AVD Manager → start an emulator
# OR (command-line):
emulator -avd <your-avd-name> &
adb wait-for-device
```

**Step 2: Navigate to the RcomFTPAutomation folder**

```bash
cd <repo>/RcomFTPAutomation
```

**Step 3: Run the suite**

```bash
# Auto-detect device:
./run_suite.sh

# OR specify a device explicitly:
adb devices  # note the device ID
./run_suite.sh <device-id>

# OR for CI/CD (don't auto-open report browser):
./run_suite.sh <device-id> --no-serve
```

**Step 4: View the report**

Once the suite completes, the Allure report opens in your default browser. If you used `--no-serve`, open it manually:

```bash
allure serve RcomFTPAutomation/reports/allure-results/
```

### Expected Runtime

| Configuration | Time |
|---|---|
| 2P scenarios (5 test files × 1 config) | ~15 min total |
| 6P scenarios (5 test files × 1 config) | ~30–40 min total (longer turn timers) |
| **Full suite (2P + 6P)** | ~45–60 min |
| **APK build** | ~5 min (first time), ~1 min cached |

---

## CI/CD Execution

### GitHub Actions Workflow

A workflow file is already in the repo: `.github/workflows/gameplay-tests.yml`

**How it works:**

1. Triggered on:
   - Push to `main` or `develop`
   - Pull requests
   - Manual trigger (`workflow_dispatch`)

2. Runs on:
   - GitHub's `ubuntu-latest` runner
   - Android emulator (API 34) created fresh
   - Full suite completes in ~90 minutes

3. Artifacts:
   - Test logcats archived as GitHub Artifacts
   - Allure report available for download

### Triggering CI/CD

**Automatic (on push to main/develop):**

Just push — the workflow triggers automatically.

**Manual (from GitHub UI):**

1. Go to your repo on GitHub
2. Click **Actions**
3. Select **Gameplay Test Suite**
4. Click **Run workflow** (blue button)
5. Choose a branch, click **Run workflow**

### Viewing CI/CD Results

1. Go to **Actions** tab on GitHub
2. Click the latest **Gameplay Test Suite** run
3. Scroll down to **Artifacts** → download the zip
4. Extract and open `allure-results/index.html` in a browser

### Customizing the Workflow

Want to run on a different schedule? Edit `.github/workflows/gameplay-tests.yml`:

```yaml
on:
  # Run every day at 2 AM UTC:
  schedule:
    - cron: '0 2 * * *'
  # Keep push/PR triggers:
  push:
    branches: [main, develop]
  pull_request:
```

---

## Troubleshooting

### "No device found (adb devices)"

**Symptom:** `run_suite.sh` fails with "No device found."

**Fix:**
1. Ensure device is plugged in (USB cable must be physical, not wireless unless ADB over IP is set up).
2. Check `adb devices` — should list your device.
3. If device shows `unauthorized`, unlock it and tap "Allow" on the USB debugging prompt.
4. Retry: `./run_suite.sh`

### "Android SDK not found"

**Symptom:** `flutter` commands fail with "Could not find Android SDK."

**Fix:**

```bash
# Set ANDROID_HOME explicitly:
export ANDROID_HOME=~/Library/Android/sdk  # macOS
# OR
export ANDROID_HOME=/usr/lib/android-sdk    # Linux

# Then retry:
flutter doctor
```

### "Flutter 3.41.6 not found"

**Symptom:** `flutter --version` shows a different version, or command not found.

**Fix:**

```bash
# Make sure you're using FVM's Flutter:
fvm use 3.41.6
# This modifies .fvm/fvm_config.json

# Verify:
flutter --version  # should now show 3.41.6

# If still wrong, activate FVM-managed Flutter:
fvm flutter --version
# (use "fvm flutter" instead of just "flutter" if PATH is overridden)
```

### "Patrol test hangs or times out"

**Symptom:** Test hangs indefinitely, or `run_test.sh` kills it with "WATCHDOG: patrol test exceeded XXXs."

**This is expected behavior for 6P scenarios**, especially Drop & Leave, due to a known app-side bug (chip settlement delayed until all other players finish). The watchdog catches this and the test flags it as `KNOWN ISSUE` in the report.

**If 2P times out unexpectedly:**
1. Check device logs: `adb logcat | grep "rummy\|RummyGame"` — look for crashes.
2. Ensure device is responsive: `adb shell input keyevent 82` (lock/unlock).
3. Retry the specific test:
   ```bash
   ./run_test.sh suites/gameplay/first_drop_test.dart <device> points-2p
   ```

### "Allure report shows all tests as FAILED"

**Symptom:** Even passing tests show red.

**Likely cause:** Logcat capture failed (empty file).

**Fix:**
1. Check `reports/logcat_*.txt` file sizes:
   ```bash
   ls -lh reports/logcat_*.txt
   ```
   If any are 0 bytes, the test's logcat wasn't captured (adb disconnect).

2. Ensure device stayed connected throughout:
   ```bash
   adb shell echo "test"  # if this fails, device disconnected
   ```

3. Retry: `./run_suite.sh`

### "Test passes locally but fails in CI/CD"

**Common causes:**

1. **Different Flutter version in CI** — GitHub Actions may have a different cached version. The workflow explicitly installs 3.41.6 via FVM, so this shouldn't happen, but check the workflow log.

2. **Emulator vs. physical device differences** — 6P scenarios can be slower on emulator. The watchdog (300s for 6P) should handle it, but if it's cutting it close, your CI might be underpowered.

3. **Network-dependent guest login** — QA1 guest creation can be flaky. If it fails in CI, it's usually a temporary backend issue, not your test. Retry.

---

## FAQ

**Q: Can I run individual test files instead of the full suite?**

A: Yes.
```bash
./run_test.sh suites/gameplay/first_drop_test.dart <device> points-2p
```

**Q: Can I run only 6P (skip 2P)?**

A: Yes, it's a config arg:
```bash
./run_test.sh suites/gameplay/first_drop_test.dart <device> points-6p
```

**Q: How do I disable the watchdog (e.g., for debugging)?**

A: Pass `WATCHDOG_SECS`:
```bash
WATCHDOG_SECS=1800 ./run_test.sh suites/gameplay/drop_and_leave_test.dart <device> points-6p
```
This extends the timeout to 30 minutes (useful for adding `await tester.pumpAndSettle()` debug pauses).

**Q: Where are the detailed logs?**

A: In `reports/logcat_<test>_<timestamp>.txt`. Open the file to see the full test trace, including 🃏 VIOLATION markers for assertions that failed but didn't stop the test.

**Q: Can I integrate this into Jenkins / GitLab CI / Azure Pipelines?**

A: Yes. The core is `./run_suite.sh`, which is shell-agnostic. You'd need to:
1. Set up the same prerequisites (Java, Android SDK, FVM, Patrol, Flutter).
2. Run `./run_suite.sh <device-id> --no-serve`.
3. Archive `reports/` as test artifacts.

The GitHub Actions example above is portable to other CI platforms.

