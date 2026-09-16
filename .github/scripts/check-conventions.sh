#!/usr/bin/env bash
# Static, MATLAB-free convention checks shared by the "smoke" gate
# (develop) and the "full-suite" gate (main). No MATLAB is available on
# GitHub-hosted runners, so this only catches what can be verified from
# the diff and the tree -- it is NOT a substitute for running
# tests/run_all_tests.m locally (see Appendix_Branching_Model_Bootstrap.md,
# Case B / Option 2, and .github/pull_request_template.md).
#
# Usage: check-conventions.sh <base-ref-or-sha>
set -uo pipefail
fail=0
base="$1"

# Only src/ and tests/ follow the repo's own MATLAB conventions (arguments
# blocks, no i/j, resetPath over pathdef, ...). mex/src/tests/ holds a
# legacy C-project test harness moved in as-is -- not in scope here.
changed_m=$(git diff --name-only "$base"...HEAD -- 'src/*.m' 'src/**/*.m' 'tests/*.m' 2>/dev/null || true)

for f in $changed_m; do
  [ -f "$f" ] || continue
  # Lint only lines this change actually adds, not the whole file -- most
  # of this legacy codebase still has pre-existing i/j loops (that's Fase 4's
  # own unmarked TODO item), so whole-file linting would fail CI on any
  # future touch to nearly any file for reasons unrelated to that change.
  added=$(git diff -U0 "$base"...HEAD -- "$f" 2>/dev/null | grep -E '^\+' | grep -v '^\+\+\+' | sed 's/^\+//')
  if echo "$added" | grep -qE '^\s*for\s+[ij]\s*='; then
    echo "::error file=$f::adds 'i' or 'j' as a loop variable (CLAUDE.md: never use i, j as loop variables)"
    fail=1
  fi
  if echo "$added" | grep -q 'matlabpath(pathdef)'; then
    echo "::error file=$f::adds a matlabpath(pathdef) reset (wipes the user's own path) -- use tests/resetPath.m instead"
    fail=1
  fi
done

bad_src=$(git ls-tree -r --name-only HEAD -- src 2>/dev/null | grep -E '^src/.+/' | grep -vE '^src/\+(OM4MClassLib|Zernikes)/' || true)
if [ -n "$bad_src" ]; then
  echo "::error::src/ must stay flat except the +OM4MClassLib and +Zernikes packages (CLAUDE.md 'Estructura'). Offending paths:"
  echo "$bad_src"
  fail=1
fi

bad_tests=$(git ls-tree -r --name-only HEAD -- tests 2>/dev/null | grep -E '^tests/.+/' | grep -vE '^tests/fixtures/README\.md$' || true)
if [ -n "$bad_tests" ]; then
  echo "::error::tests/ must stay flat; tests/fixtures/ must stay empty except its README.md (CLAUDE.md 'Estructura' / 'Tests'). Offending paths:"
  echo "$bad_tests"
  fail=1
fi

bad_mex=$(git ls-tree -r --name-only HEAD -- mex 2>/dev/null | grep -iE '(^|/)(Debug|Release)/|\.(obj|pdb)$' || true)
if [ -n "$bad_mex" ]; then
  echo "::error::mex/ build intermediates (Debug/, Release/, .obj, .pdb) must not be committed (CLAUDE.md 'MEX'). Offending paths:"
  echo "$bad_mex"
  fail=1
fi

exit $fail
