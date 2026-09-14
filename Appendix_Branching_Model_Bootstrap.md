# Appendix — Branching Model Bootstrap Guide (Python vs. MATLAB)

> Part of: Claude Code for Python Developers: Hands-On Agentic Coding
> Project: NowcastingCLI (`CCPD-nowcastingcli`)
> Related: [Module 7 — CI/CD: GitHub Actions](./Module7_Course_Notes.md) (the branch model and workflows this appendix generalizes)
> See also: [Course Notes Index](./Course_Notes_Index.md)
> Version: 1.0.0 (2026-09-14) — see [Version History](#version-history) at the end of this file

Unlike the seven numbered modules, this appendix is not part of
NowcastingCLI's build narrative — it's a **portable, self-contained
instruction set** extracted from Module 7's branch model, written so
another Claude Code instance can reproduce the same `develop`/`main`
model, gate/confirmation CI pattern, and four working scenarios in a
**new** repository, in either a Python or a MATLAB project. It exists
because the two stacks diverge on one key point: Python tests can run
directly on GitHub-hosted runners, but MATLAB tests cannot (no MATLAB
installation or license there), which forces a different design for the
CI gate. Everything else — branches, PR directions, branch protection
shape, the four scenarios — is identical between the two.

---

> Audience: a Claude Code instance responsible for bootstrapping a **new**
> GitHub repository. This document specifies a two-branch model with a
> gate/confirmation CI pattern and four working scenarios, replicated from
> the `CCPD-nowcastingcli` repo (Python). Two tracks are given below:
>
> - **Case A — Python**: tests run directly on GitHub-hosted runners.
> - **Case B — MATLAB**: tests **cannot** run on GitHub-hosted runners (no
>   MATLAB installation/license there). The branch/PR model and the
>   gate/confirmation *shape* stay identical — only what the automated
>   check actually verifies, and where real test execution happens,
>   changes.
>
> Read §1–§4 (shared), then follow whichever of §5A/§5B matches the new
> repo's language, then §6 (shared) and the checklist for that case.

## 1. Branches (both cases)

Two long-lived branches:

| Branch | Role | Notes |
|---|---|---|
| `develop` | Default branch — everyday feature integration | All feature work and PRs target this branch. Set as the repo's default branch. |
| `main` | Stable / production-ready branch | Updated only via PR from `develop` (or a `hotfix/*` branch) at release time. Protected: no direct pushes, no force-pushes, no deletion. |

```bash
git checkout -b develop
git push -u origin develop
gh repo edit --default-branch develop
```

`main` already exists from repo init; keep it pointed at the same initial commit as `develop` until the first release.

## 2. The gate/confirmation pattern (both cases)

Both CI workflows share one shape: **the same job runs on two different
triggers with two different roles.**

| Event | Role | Can it block a merge? |
|---|---|---|
| `pull_request → develop` / `pull_request → main` | **Gate.** Required status check — branch protection blocks merge until it's green. | Yes |
| `push → develop` / `push → main` | **Confirmation.** Fires the instant a merge lands (the merge button *is* a push event). Can't block anything retroactively, but catches drift the PR check never saw. | No — informational only |

What differs between Python and MATLAB is **what runs inside the gate job**,
not the trigger shape above. See §5A / §5B.

## 3. Branch protection (both cases, apply after choosing job names)

```bash
# develop: require the "smoke" check (name from whichever case's workflow you used)
gh api -X PUT repos/<OWNER>/<REPO>/branches/develop/protection \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["smoke"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

# main: require the "full-suite" check
gh api -X PUT repos/<OWNER>/<REPO>/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["full-suite"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

Notes, deliberate and non-obvious:
- `enforce_admins: false` on **both** branches lets the repo owner bypass the gate for trivial direct pushes to `develop` (Scenario 1). It is not meant to invite bypassing `main` casually — a push to `main` can trigger a real, irreversible release.
- `required_pull_request_reviews: null` — no mandatory human approval count in Case A, where the automated check is the real gate. **In Case B (MATLAB), flip this** — see §5B, since there the automated check alone can't verify correctness and a human approval becomes part of the real gate.

## 4. The four working scenarios (shape is identical in both cases)

**1. Normal Development** — small, low-risk changes (docs, trivial fixes) pushed directly to `develop`, no PR. Fires `push → develop` only, relying on `enforce_admins: false`. Reserve this for changes where CI wouldn't catch anything meaningful anyway — real code changes go through Scenario 2.

**2. Feature Work** — branch off `develop` (`feature/xyz`), PR back into `develop`. Fires `pull_request → develop` as the **required gate**. On merge, `push → develop` fires again as confirmation.

**3. Build / Release** — PR from `develop` into `main`. Fires `pull_request → main` (`full-suite`) as the **required gate** — no tagging/publishing on a PR preview. On merge, `push → main` reconfirms `full-suite`, then runs tag/release/publish/docs jobs. Bump the version in the project manifest as part of this PR — that's what tagging keys off of.

**4. Hotfix** — `main` is live and broken, `develop` has unreleasable work in flight. Branch `hotfix/xyz` **from `main`**, fix, bump the patch version, PR `hotfix/xyz → main` (same gate as Scenario 3). On merge, `push → main` tags/releases the patch. The one manual step with **no workflow trigger behind it**: back-merge into `develop` afterward via a PR from a branch like `merge-main-into-develop` (`main → develop`, **real merge commit, not squash** — squashing would silently drop the hotfix's actual commits from `develop`'s history while still bringing its content). Skipping this means the hotfix silently disappears from the next regular release cut from `develop`.

| Scenario | Head branch | Base branch | Required check |
|---|---|---|---|
| Feature work | `feature/xyz` | `develop` | `smoke` |
| Release | `develop` | `main` | `full-suite` |
| Hotfix | `hotfix/xyz` | `main` | `full-suite` |
| Back-merge after release/hotfix | `merge-main-into-develop` (or similar) | `develop` | `smoke` |

---

## 5A. Case A — Python (tests run on GitHub-hosted runners)

### `smoke-tests.yml` — the `develop` gate

```yaml
name: Smoke Tests
on:
  pull_request:
    branches: [develop]
  push:
    branches: [develop]

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with: { python-version: "3.x" }
      - run: pip install -e .[dev]
      - run: pytest -m smoke --no-cov -v   # fast subset only
```

### `release.yml` — the `main` pipeline

```yaml
name: Release Pipeline
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  full-suite:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with: { python-version: "3.x" }
      - run: pip install -e .[dev,docs]
      - run: pytest --cov --cov-report=xml
      - uses: actions/upload-artifact@v7
        with: { name: coverage, path: coverage.xml }
      - run: mkdocs build

  deploy-docs:
    needs: full-suite
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions: { contents: write }
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with: { python-version: "3.x" }
      - run: pip install -e .[dev,docs]
      - run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
      - run: mkdocs gh-deploy --force --clean

  tag-and-release:
    needs: full-suite
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions: { contents: write }
    outputs:
      released: ${{ steps.tag.outputs.released }}
    steps:
      - uses: actions/checkout@v7
        with: { fetch-depth: 0 }
      - id: tag
        run: |
          VERSION=$(python -c "import tomllib; print(tomllib.load(open('pyproject.toml','rb'))['project']['version'])")
          if git rev-parse "v$VERSION" >/dev/null 2>&1; then
            echo "Tag v$VERSION already exists — skipping."
            echo "released=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi
          git tag "v$VERSION"
          git push origin "v$VERSION"
          gh release create "v$VERSION" --generate-notes
          echo "released=true" >> "$GITHUB_OUTPUT"
        env:
          GH_TOKEN: ${{ github.token }}

  build-and-publish:
    needs: tag-and-release
    if: github.event_name == 'push' && needs.tag-and-release.outputs.released == 'true'
    runs-on: ubuntu-latest
    permissions: { id-token: write }   # PyPI Trusted Publishing (OIDC) — no stored token
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with: { python-version: "3.x" }
      - run: pip install build
      - run: python -m build
      - uses: pypa/gh-action-pypi-publish@release/v1
```

Key mechanics: `full-suite` runs on both `pull_request` and `push` (the required check for `main`); every job after it is guarded by `if: github.event_name == 'push'` so a PR preview never ships anything; the tag step reads the version from `pyproject.toml` and skips cleanly (not a failure) if that version is already tagged, making no-version-bump merges a no-op release.

---

## 5B. Case B — MATLAB (tests cannot run on GitHub-hosted runners)

**The constraint:** GitHub-hosted runners have no MATLAB installation or
license, so `runtests(...)` cannot execute there. This breaks the Case A
assumption that the required status check *is* the real correctness gate.
Two ways to handle it — pick based on what's actually available for this repo:

### Option 1 (preferred if it exists): a self-hosted runner with MATLAB

If a machine with a licensed MATLAB install can be registered as a GitHub
Actions self-hosted runner, the gate/confirmation pattern stays byte-for-byte
identical to Case A — only `runs-on` changes:

```yaml
name: Smoke Tests
on:
  pull_request:
    branches: [develop]
  push:
    branches: [develop]

jobs:
  smoke:
    runs-on: [self-hosted, matlab]
    steps:
      - uses: actions/checkout@v7
      - uses: matlab-actions/run-tests@v2
        with:
          select-by-folder: tests/smoke
```

Same for `release.yml`'s `full-suite` (`select-by-folder: tests`, or a tag-based selection). If this option is available, use it and treat the rest of this document identically to Case A — the required-check names (`smoke`, `full-suite`) and branch protection in §3 don't change.

### Option 2 (no self-hosted runner): CI checks what it can; a human confirms the rest

This is the default assumption for this document per the stated constraint.
Split the gate into two parts:

1. **Automated part (runs on `ubuntu-latest`, no MATLAB needed):** whatever
   doesn't require executing `.m` code — repo/file structure checks, that
   changed `.m` files have a matching test file, changelog/version-bump
   presence, markdown/docs build, packaging step (`.mltbx` assembly) if the
   project ships one. This becomes the actual required status check.
2. **Manual part (real correctness gate):** the developer runs
   `runtests` locally in MATLAB before opening the PR, and pastes the
   result into the PR description. A **required human review approval**
   substitutes for the automated test gate GitHub can't provide.

```yaml
name: Structure Check
on:
  pull_request:
    branches: [develop]
  push:
    branches: [develop]

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Verify every changed .m file has a matching test
        run: |
          # adapt to this repo's actual layout/convention, e.g.:
          # for f in $(git diff --name-only origin/develop... -- '*.m' | grep -v '^tests/'); do
          #   test -f "tests/test_$(basename "$f")" || { echo "Missing test for $f"; exit 1; }
          # done
          echo "placeholder — implement the real check for this repo"
```

Branch protection differs from §3 for this option — add a required reviewer since the automated check alone doesn't verify correctness:

```bash
gh api -X PUT repos/<OWNER>/<REPO>/branches/develop/protection \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["smoke"] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

Apply the same `required_approving_review_count: 1` to `main`'s protection.

**PR template requirement:** add a checklist item to `.github/pull_request_template.md`:

```markdown
- [ ] Ran `runtests` locally in MATLAB — all tests pass (paste summary below)
```

The `release.yml`-equivalent `main` pipeline follows the same split: an
`ubuntu-latest` job does packaging/docs/tagging (no MATLAB needed for
`gh release create` or `git tag`), and the "did the tests actually pass"
question is answered by the human reviewer approving the PR, not by CI.
There is no PyPI-equivalent auto-publish step by default for MATLAB —
`tag-and-release` can still tag and create a GitHub Release with the
built `.mltbx` attached as a release asset; submitting to MATLAB File
Exchange, if desired, remains a manual step.

### Scenario nuance for Case B

Scenarios 1–4 in §4 keep the same branches/PR directions. The only change:
wherever §4 says "Fires `pull_request → develop` as the required gate,"
read that as "the automated structure check runs *and* a human reviewer
confirms local test results were pasted into the PR" for Case B under
Option 2.

---

## 6. Setup checklist

**Both cases:**
1. `git checkout -b develop && git push -u origin develop`
2. `gh repo edit --default-branch develop`
3. Document the model in the new repo's `README.md` (`## Branching Model` + short CI/CD summary).
4. Set the initial version in the project manifest below the first intended release tag.

**Case A (Python) additionally:**
5. Add `.github/workflows/smoke-tests.yml` and `release.yml` from §5A.
6. Tag a fast test subset with `@pytest.mark.smoke`.
7. Apply branch protection from §3 as-is (`required_pull_request_reviews: null`).

**Case B (MATLAB) additionally:**
5. Confirm whether a self-hosted MATLAB runner is available (Option 1) — if yes, use §5A's workflows with `runs-on: [self-hosted, matlab]` and `matlab-actions/run-tests`, and skip the rest of this list.
6. If no self-hosted runner (Option 2): implement the real structure-check logic for `smoke`/`full-suite` (don't ship the placeholder), add `.github/pull_request_template.md` with the "ran tests locally" checklist, and apply branch protection with `required_approving_review_count: 1` on both `develop` and `main`.
7. Decide the packaging/publish story (`.mltbx` as a release asset, and/or manual File Exchange submission) and wire only the tagging/packaging part into CI — never claim automated test verification that didn't happen.

---

## Version History

This appendix is versioned independently of NowcastingCLI's own
`pyproject.toml` version — it tracks the bootstrap guide's own content,
since it's meant to be copied into other repos and updated over time as
new cases or corrections come up. Bump the minor version for a new
section/case, the patch version for a correction/clarification, and record
every change here.

| Version | Date | Changes |
|---|---|---|
| 1.0.0 | 2026-09-14 | Initial version: shared branch model (§1–4), Case A (Python, tests on GitHub-hosted runners, §5A), Case B (MATLAB, tests cannot run on GitHub-hosted runners — self-hosted runner or human-reviewed gate, §5B), setup checklist (§6). |
