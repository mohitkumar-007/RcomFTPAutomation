# Gameplay Test Suite — RcomFTPAutomation

Automated Patrol-based gameplay tests for the Rummy app with GitHub Actions CI/CD.

---

## Quick Start

### You Need TWO Repositories

```bash
# 1. Clone the app (Prism)
git clone https://github.com/your-org/prism.git ~/Developer/prism

# 2. Clone the tests (this repo)
git clone https://github.com/your-org/RcomFTPAutomation.git ~/LearningMaterials/RcomFTPAutomation
```

### Setup (One Time)

Follow [TEAM_SETUP.md](TEAM_SETUP.md) for:
- FVM 3.41.6
- Android SDK + emulator
- Patrol CLI
- Allure CLI

### Run the Tests

```bash
cd ~/LearningMaterials/RcomFTPAutomation
./run_suite.sh
```

Report opens automatically. Done.

---

## What Gets Tested

One guest session running sequentially:

1. **Pregame** — guest login, table setup
2. **First Drop** (2P + 6P) — drop before drawing
3. **Mid Drop** (2P + 6P) — drop after one turn
4. **Invalid Declare** (2P + 6P) — wrong declaration
5. **Valid Declare** (2P + 6P) — correct declaration
6. **Drop & Leave** (2P + 6P) — real Leave icon + chip deduction

**Total:** ~45–60 min locally, ~90 min on GitHub Actions

---

## Execution Models

| Who | How | Time | Cost |
|---|---|---|---|
| **QA Engineer** | `./run_suite.sh` locally | 45–60 min | $0 |
| **Stakeholder** (no device) | GitHub Actions Artifacts | ~90 min | $0 |
| **DevOps** (daily automation) | GitHub Actions cron schedule | Nightly | $0 |

---

## Documentation

- **[TEAM_SETUP.md](TEAM_SETUP.md)** — Step-by-step local setup
- **[QUICK_START.md](QUICK_START.md)** — 30-second reference
- **[TEAM_CHECKLIST.md](TEAM_CHECKLIST.md)** — Role-based onboarding
- **[DEVICE_OPTIONS.md](DEVICE_OPTIONS.md)** — Device strategies (local vs. cloud)
- **[CI_CD_SETUP.md](CI_CD_SETUP.md)** — Enable GitHub Actions automation

---

## Repository Structure

This repo (RcomFTPAutomation) is the **orchestration & reporting layer**.

Test code lives in the **Prism app repo**:

```
~/Developer/prism/apps/rummy/integration_test/
├── suites/gameplay/           ← test files
│   ├── first_drop_test.dart
│   ├── mid_drop_test.dart
│   ├── invalid_declare_test.dart
│   ├── valid_declare_test.dart
│   ├── drop_and_leave_test.dart
│   └── table_setup_test.dart
└── support/                   ← shared helpers
    ├── drivers/gameplay_driver.dart
    ├── pages/lobby_pages.dart
    ├── scoring/points_engine.dart
    ├── report/step_log.dart
    └── config/table_config.dart
```

This repo contains:

```
RcomFTPAutomation/
├── run_suite.sh                    ← Full sequence orchestrator
├── run_test.sh                     ← Single test runner
├── generate_report.sh              ← Allure report builder
├── tool/convert_to_allure.dart     ← Allure converter
├── .github/workflows/gameplay-tests.yml  ← GitHub Actions CI/CD
├── reports/                        ← Generated Allure output
└── *SETUP*.md / CHECKLIST.md       ← Team documentation
```

---

## Custom Paths

If you cloned Prism to a non-standard location:

```bash
RUMMY_DIR=/my/custom/path/prism/apps/rummy ./run_suite.sh
```

The script auto-detects the default `~/Developer/prism/apps/rummy`, but you can override.

---

## Automated Daily Runs

GitHub Actions runs on:
- ✅ Push to `main` or `develop`
- ✅ Pull requests
- ✅ Manual trigger
- ✅ **Daily schedule** (2 AM UTC, configurable)

View: **GitHub repo → Actions → Gameplay Test Suite → latest run → Artifacts**

---

## Known Issues

**6P Drop & Leave** will timeout and show as FAILED with KNOWN ISSUE violations. This is an app-side bug (chip settlement delayed until all other players finish their deal). Watchdog catches the post-completion teardown hang. Not a test defect.

---

## Troubleshooting

See [TEAM_SETUP.md](TEAM_SETUP.md) for common issues:
- Device not found
- Flutter version wrong
- RUMMY_DIR not found
- Test hangs or timeouts


