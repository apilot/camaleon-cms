# Workflows

## Phase 1: Branch Initialization & Context (MANDATORY)
**You must perform these steps before writing any code:**

1.  **Sync & Branch:**
    - Ensure you are on the latest `master`.
    - Create a new branch: `git checkout -b <type>/<brief-description>`.
    - *Protocol:* Announce the branch name to the user immediately.
2.  **Context Gathering (Task Lifecycle Triggers):**
    - Check `docs/ai/knowledge/` and `docs/ai/decisions/`.
    - Read `docs/ai/mechanical_overrides.md` to identify if this task requires "Step-0 Clean-up."
3.  **Vulnerability Triage (Security Tasks Only):**
    - If this is a security fix, you MUST follow the **Vulnerability Triage Protocol** in Phase 2 before writing the fix.

---

## Phase 2: Execution & CI Parity

### A. Vulnerability Triage Protocol (Hypothesis-Driven)
**Objective:** Verify that a reported vulnerability is "Legit" (exploitable or present in our specific context) before acting.

1.  **Step 1: Proof of Presence:** Do not assume the report is correct.
    - **For Dependency Reports:** Run `bundle exec bundle-audit check`. Does the reported gem/version match our `Gemfile.lock`?
    - **For Code/Static Reports:** Run `bin/brakeman -z --only-files <file_path>`. Does Brakeman flag the specific line mentioned?
    - **Manual Grep:** If no tool finds it, `grep -r` the codebase for the vulnerable pattern.
2.  **Step 2: Legitimacy Verdict:** State your finding to the user. You must pick one:
    - ✅ **Legit:** "Confirmed. We are using version X; version Y is required." or "Confirmed. Brakeman flags this as a High risk SQLi."
    - ❌ **False Positive:** "The report is for a library we don't use." or "The code pattern exists but is in a test-only file not reachable in production."
    - ⚠️ **Unverifiable:** "I see the code, but my tools cannot confirm the risk. I recommend a deeper manual audit."
3.  **Step 3: Authorization to Proceed:** ONLY if the verdict is ✅ Legit:
    - Follow the standard "Goal-Driven Execution": **Write a failing test that reproduces the risk** (if possible) before applying the fix.

### B. Development & Testing
- **Goal-Driven Execution:** "Fix the bug" → Write a test that reproduces it, then make it pass.
- **Security Fixes:** Fixing a vulnerability MUST include spec coverage.
    - **Write a test that exposes the vulnerability** before applying the fix (unless reproducing is infeasible).
    - **Integration/feature specs are preferred over controller specs** for vulnerability reproduction.
- **Spec Coverage:** All code changes must be covered by specs.
- **Commands:** Live in `docs/ai/testing.md`.
- **Note:** Rails commands (e.g., `rails routes`, `zeitwerk:check`) MUST be run from the `spec/dummy` folder. Use subshells to avoid getting stuck there: `(cd spec/dummy && bin/rails ...)`

### C. CI Parity (Security & Lint)
Your code must pass these local checks to match CI:
- `bin/brakeman --no-pager`
- `bin/rubocop -A` (Auto-correct only what you touched)
- **Lifecycle Trigger:** During work, verify or contradict existing hypotheses in the decision journal.

---

## Phase 3: Commit Guidelines

**🔴 MANDATORY: `[skip ci]` for Non-Code Commits**

Before EVERY commit, check: **Does this commit contain ONLY documentation, changelog, or config changes with NO code changes?**

If YES, you MUST format the commit message as:
```
<commit subject>

[skip ci]
```

**Examples of commits requiring `[skip ci]`:**
- Documentation updates (`.md` files, README, docs/)
- Changelog entries (`CHANGELOG.md`)
- Configuration files with no code path changes
- Comment-only changes

---

## Phase 4: PR Submission & Maintenance

1.  **PR Protocol:** Generate a description following these STRICT negative constraints:
    - **NO** `Files Changed` section.
    - **NO** Test failure/example counts.
    - **NO** Verification logs/commands.
    - **NO** Commit SHAs or history references.
    - **REQUIRED:** One sentence on **User-Visible Impact** (or state "None").
    - **REQUIRED:** A "What and Why" summary.

2.  **Metadata Maintenance:** If you change setup, test, or CI commands, you are **REQUIRED** to update:
    - `AGENTS.md`
    - `docs/ai/testing.md` (if applicable)
    - `README.md`
    *All updates must be part of the same PR.*

3.  **Changelog:** After creating the PR, you MUST generate and commit a changelog entry referencing the PR:
    ```
    - **Security fix:** Fix mass assignment and open redirect vulnerabilities in SitesController, [#1152](https://github.com/owen2345/camaleon-cms/pull/1152)
    ```

4.  **Final Trigger:** Before completion, self-audit against `docs/ai/quality/criteria.md`.
