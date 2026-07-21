# CI/CD Setup — Enable Automated Daily Runs

## Note on Repo Structure

The workflow assumes **two separate repositories:**
- `prism` (the app source code, at `github.com/your-org/prism`)
- `RcomFTPAutomation` (this test suite repo)

The workflow in this repo (`RcomFTPAutomation`) checks out **both** during CI/CD (see the workflow file, steps for "Checkout RcomFTPAutomation" and "Checkout Prism" or similar). If your setup differs, update the workflow before committing.

---

You have already been provided with a GitHub Actions workflow. This document shows you how to **commit it to your repo** and **enable daily automatic runs**.

---

## Step 1: Push the Workflow to Git

The workflow file is already created at `.github/workflows/gameplay-tests.yml`.

**Commit and push it:**

```bash
cd /Users/mohit.kumar/LearningMaterials/RcomFTPAutomation

git add .github/workflows/gameplay-tests.yml
git add run_suite.sh
git add generate_report.sh
git add TEAM_SETUP.md QUICK_START.md DEVICE_OPTIONS.md TEAM_CHECKLIST.md CI_CD_SETUP.md

git commit -m "feat: add automated gameplay test suite with GitHub Actions CI/CD

- run_suite.sh: orchestrates full 2P+6P sequence with guest-only session
- .github/workflows/gameplay-tests.yml: daily + on-demand CI/CD pipeline
- TEAM_SETUP.md: step-by-step local execution guide
- QUICK_START.md: 30-second reference
- DEVICE_OPTIONS.md: local vs. cloud device farming
- TEAM_CHECKLIST.md: role-based checklist
"

git push origin main  # or your main branch
```

---

## Step 2: Verify Workflow on GitHub

1. Go to your GitHub repo
2. Click **Actions** tab (top navigation)
3. You should see **"Gameplay Test Suite"** listed on the left
4. Status: **"Awaiting trigger"** (no runs yet)

If you don't see it:
- Check the `.github/workflows/` directory is in your repo
- Refresh the page
- Ensure you pushed to `main` or `develop` (workflow is triggered on those branches)

---

## Step 3: Enable Daily Schedule (Optional)

By default, the workflow runs on:
- ✅ Push to `main` or `develop`
- ✅ Pull requests
- ✅ Manual trigger

To add a **daily schedule** (e.g., every night at 2 AM UTC):

**Edit `.github/workflows/gameplay-tests.yml`:**

Find the `on:` section and add:

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
  workflow_dispatch:
  # Add this:
  schedule:
    - cron: '0 2 * * *'  # Every day at 2 AM UTC (= 9:30 PM IST)
```

**Save and push:**

```bash
git add .github/workflows/gameplay-tests.yml
git commit -m "ci: enable daily gameplay test schedule (2 AM UTC)"
git push origin main
```

**Verify:** Go to Actions → Gameplay Test Suite. You'll see a new event: `schedule`.

---

## Step 4: Customize the Schedule (If Needed)

The cron format is: `minute hour day month day-of-week`

**Examples:**

```yaml
# Every day at 2 AM UTC
- cron: '0 2 * * *'

# Every day at 9:30 PM IST (2 AM UTC)
- cron: '30 21 * * *'

# Every weekday (Mon–Fri) at 9 AM UTC
- cron: '0 9 * * 1-5'

# Every Monday at 6 AM UTC
- cron: '0 6 * * 1'

# Every 6 hours
- cron: '0 */6 * * *'
```

Use https://crontab.guru to generate times in your timezone.

---

## Step 5: Invite Team Members

Send this to your team:

---

### 📢 Announcement: Automated Gameplay Test Suite

Hi team,

The gameplay test suite is now **fully automated** on GitHub Actions.

#### What's Running?

- ✅ **Full test sequence:** Pregame → First Drop → Mid Drop → Invalid Declare → Valid Declare → Drop & Leave
- ✅ **All configs:** 2P and 6P players
- ✅ **Frequency:** Daily at 2 AM UTC (+ on every push, + manual trigger)
- ✅ **Guest-only:** Isolated session, no login loops

#### For QA Engineers (Who Run Tests Locally)

Setup is one-time:
1. Read [TEAM_SETUP.md](https://github.com/yourrepo/RcomFTPAutomation/blob/main/TEAM_SETUP.md)
2. Install FVM, Android SDK, Patrol, Allure
3. Run: `cd RcomFTPAutomation && ./run_suite.sh`

#### For Everyone Else (View Results)

No local setup needed:
1. Go to GitHub repo → **Actions** tab
2. Click **Gameplay Test Suite** → latest run
3. Scroll to **Artifacts** → download results
4. Open `allure-results/index.html` in browser

#### Trigger a Manual Run

**Any time**, without code changes:
1. Go to GitHub repo → **Actions** → **Gameplay Test Suite**
2. Click **Run workflow** → **Run workflow** (blue button)
3. Wait ~90 min for results

#### Questions?

See [QUICK_START.md](https://github.com/yourrepo/RcomFTPAutomation/blob/main/QUICK_START.md) or #qa-automation channel.

---

---

## Step 6: Monitor First Run

Your first automated run will trigger:
1. **Immediately** after you push the workflow file (push trigger)
2. **Next scheduled time** (2 AM UTC, if you added `schedule:`)
3. **On demand** (manual trigger from GitHub UI)

**Watch it:**

1. Go to Actions → Gameplay Test Suite
2. Click the run in progress
3. Expand steps to see test execution live (updates every 30 sec)

**Troubleshooting:**

If the run fails:
- Click the run
- Scroll down to "Annotations" → see error message
- Common issues:
  - Emulator startup timeout → rerun (GH might be slow)
  - Flutter cache issues → workflows usually auto-resolve on retry
  - Network error during guest creation → transient, rerun

**Rerun a failed job:**

At the top right of any run, click **Re-run all jobs**.

---

## Step 7: Archive & Retention

**Artifacts expire after 90 days** by default on GitHub.

To keep reports longer:
1. Go to repo Settings → **Actions** → **General**
2. Set "Artifact and log retention" to your desired duration (up to 400 days)

Or download + archive manually to your own storage (Slack, S3, etc.).

---

## Step 8: Slack Notifications (Optional)

Want test results posted to Slack automatically?

**Add a Slack action** to the workflow:

Edit `.github/workflows/gameplay-tests.yml`, add at the end:

```yaml
      - name: Notify Slack on completion
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Gameplay tests: ${{ job.status }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Gameplay Test Suite*\n*Status:* ${{ job.status }}\n*Run:* <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View>"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

Then set `SLACK_WEBHOOK_URL` in repo Secrets:
1. Go to Settings → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `SLACK_WEBHOOK_URL`, Value: your Slack webhook URL (from Slack API)

---

## Summary

| Action | Command / Link |
|---|---|
| **Commit workflow** | `git push` (already done if you pushed the `.github/` folder) |
| **Verify on GitHub** | Go to **Actions** tab, see "Gameplay Test Suite" |
| **Enable daily runs** | Add `schedule:` to `on:` section in workflow file |
| **Invite team** | Share the announcement from Step 5 |
| **Trigger manually** | GitHub UI → Actions → Gameplay Test Suite → Run workflow |
| **View results** | Actions → latest run → download Artifacts |
| **Local alternative** | `./run_suite.sh` (for developers) |

---

## Done ✅

Your team can now:
1. **Push code** → tests run automatically
2. **View results** → GitHub Actions Artifacts
3. **Run locally** → `./run_suite.sh`
4. **Schedule daily** → no manual intervention needed

