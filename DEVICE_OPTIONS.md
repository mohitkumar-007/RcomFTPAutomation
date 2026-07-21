# Device Options — Local vs. Cloud vs. CI

Your tests **require a real Android device or emulator** to run. Here's how to choose:

---

## Option 1: Local Physical Device (Recommended for Daily Dev)

**Setup:**
- Plug Android phone/tablet (API 28+) into your laptop via USB
- Run: `./run_suite.sh`

**Pros:**
- Free
- Fast (no network latency)
- Easy to debug (you see the device in your hand)
- Perfect for developers iterating on tests

**Cons:**
- Only one person can use it at a time
- Requires a device physically present

**Cost:** $0 (if you already own a device)

---

## Option 2: Local Android Emulator (Free, Slow)

**Setup:**
```bash
# In Android Studio:
# Tools → AVD Manager → Create Virtual Device (Pixel 4, API 34)
# Start it

# OR command-line:
emulator -avd Pixel_4_API_34 &
adb wait-for-device
```

**Pros:**
- Free
- No physical device needed
- CI/CD-friendly (GitHub Actions uses this)

**Cons:**
- Slower than physical device (6P scenarios may run 2x longer)
- Requires ~8 GB RAM + CPU cores
- Not great for parallel testing

**Cost:** $0

---

## Option 3: GitHub Actions (Free, Automated)

**Setup:** Already configured in `.github/workflows/gameplay-tests.yml`

**How it works:**
1. Push to `main`/`develop` → GitHub Actions spins up an emulator
2. Runs full suite (~90 min) automatically
3. Archives results as Artifacts

**Pros:**
- Free
- Fully automated (no manual intervention)
- Daily/scheduled runs trivial (cron in workflow)
- Team doesn't need a device
- Historical record of all runs

**Cons:**
- Slower than local (emulator + GH runner overhead)
- 90 min per run adds up with frequent schedules
- Reports not instantly browsable (download from Artifacts)

**Cost:** $0 (GitHub's free tier includes runners)

**Daily scheduled run example:**

Edit `.github/workflows/gameplay-tests.yml`:
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Every day at 2 AM UTC
```

---

## Option 4: Cloud Device Farm (Paid Alternatives)

**Since you don't have BrowserStack**, here are similar services:

### AWS Device Farm
- **Cost:** ~$1–5 per test run (depends on device type)
- **Setup:** ~1 day (API integration)
- **Devices:** 100s of real Android devices
- **Best for:** Enterprise, high-volume testing, multiple device variants

### Google Cloud Testing (Firebase Test Lab)
- **Cost:** Free tier + ~$1.50/device-hour
- **Setup:** ~1 day (Firebase console + SDK)
- **Devices:** Real devices in Google data centers
- **Best for:** Google Play apps, immediate device access

### Sauce Labs
- **Cost:** ~$0.10–1 per test minute
- **Setup:** ~1 day (REST API)
- **Devices:** Real + virtual, cloud-based
- **Best for:** CI/CD pipelines, parallel testing

### TestProject
- **Cost:** Free tier + paid (on-premise server)
- **Setup:** ~2 days (server + agent)
- **Devices:** Real devices via on-premise agents
- **Best for:** Teams wanting on-premise privacy

**How to integrate:**
1. Create account on chosen service
2. Upload APK + test artifact to their platform
3. Adapt `run_suite.sh` to deploy via their API instead of local ADB
4. Trigger from CI/CD

---

## Recommended Setup for Your Team

### For **Daily Regression Testing (Automated, No Manual Work):**

**Use GitHub Actions + Emulator** (Option 3)

```bash
# Already set up — just push to main
git push origin develop
# Workflow triggers automatically → results available in 90 min
```

**Cost:** $0 (GitHub free tier)

**Team doesn't need to do anything** — just view Artifacts after it runs.

---

### For **Quick Developer Iteration:**

**Use Local Device** (Option 1)

```bash
# One developer runs locally with their phone plugged in
./run_suite.sh
# Results in 45–60 min on their machine
```

**Cost:** $0

---

### For **Parallel Testing (Multiple Devices Simultaneously):**

**Use Cloud Device Farm** (Option 4)

Requires:
- Upfront integration work (~1–2 days)
- Ongoing costs (~$5–100/month depending on frequency)

**Example: AWS Device Farm + GitHub Actions**

```bash
# .github/workflows/gameplay-tests.yml
- name: Upload to AWS Device Farm
  run: |
    aws devicefarm create-run \
      --project-arn arn:aws:... \
      --app-arn arn:aws:... \
      ...
```

---

## Decision Matrix

| Need | Solution | Time to Setup | Cost | Best For |
|---|---|---|---|---|
| Run tests today | Local device | 10 min | $0 | Developer iteration |
| Daily automation | GitHub Actions | 5 min (already done) | $0 | Team regression suite |
| Multiple devices in parallel | Cloud farm | 2–5 days | $5–100/mo | Enterprise QA |
| CI/CD + fast feedback | Local device + GitHub Actions | 20 min | $0 | Hybrid: dev + automated |

---

## Your Current Setup Summary

✅ **Local:** FVM 3.41.6, Patrol 4.5.1, `run_suite.sh` ready
✅ **CI/CD:** `.github/workflows/gameplay-tests.yml` configured for automatic daily runs
✅ **Device:** Emulator (GH Actions) or local phone (developer)

**Next step:** Team members clone repo, follow `TEAM_SETUP.md` → `./run_suite.sh` or wait for GitHub Actions to run automatically on push.

