#!/bin/sh
# Pre-push checks shared by the dotjasonhwang sites. Each site's .husky/pre-push runs:
#   pnpm exec djh-pre-push               (or `npx djh-pre-push` in npm repos)
#   pnpm exec djh-pre-push --skip-check  (sites whose `check` script doesn't pass yet)
#
# Runs, stopping at the first failure: check (astro + eslint + prettier), unit tests, build,
# link check (internal + external, lychee) and E2E. Git runs hooks from the repo root.

skip_check=0
for arg in "$@"; do
  case "$arg" in
    --skip-check) skip_check=1 ;;
    *) echo "❌ djh-pre-push: unknown option '$arg'"; exit 2 ;;
  esac
done

fail() {
  echo "❌ $1 Push aborted."
  exit 1
}

# The site's own lockfile decides the package manager
if [ -f pnpm-lock.yaml ]; then
  run="pnpm run"
elif [ -f package-lock.json ]; then
  run="npm run"
else
  fail "No pnpm-lock.yaml or package-lock.json found."
fi

command -v lychee >/dev/null || fail "lychee not found. Install it with 'brew install lychee'."

# Shared with .github/workflows/link-check.yml
lychee_config=node_modules/@dotjasonhwang/ci/lychee.toml
[ -f "$lychee_config" ] || fail "$lychee_config not found. Is @dotjasonhwang/ci installed?"

if [ "$skip_check" -eq 1 ]; then
  echo "⏭️  Skipping checks (--skip-check)"
else
  echo "🔍 Running checks (astro + eslint + prettier)..."
  $run check || fail "Checks failed."
fi

echo "📋 Running unit tests..."
$run test || fail "Unit tests failed."

echo "🔨 Building..."
$run build || fail "Build failed."

# Internal links resolve against dist/; external links are fetched (cached for a day in .lycheecache).
# The site's own domain (from the built sitemap) is skipped: its pages are checked as files in dist/,
# and production doesn't have a page this push adds until Netlify deploys it.
site_re=$(grep -ho '<loc>[^<]*' dist/sitemap-index.xml dist/sitemap.xml 2>/dev/null | head -1 \
  | sed -E 's#^<loc>https?://(www\.)?([^/]+).*#\2#; s/\./\\./g')
echo "🔗 Checking links..."
lychee --config "$lychee_config" --root-dir "$(pwd)/dist" \
  ${site_re:+--exclude "^https?://(www\.)?$site_re(/|\$)"} \
  dist || fail "Broken links."

# dist/ was just built; sites whose Playwright config builds first skip that with E2E_SKIP_BUILD
echo "🌐 Running E2E tests..."
E2E_SKIP_BUILD=1 $run test:e2e || fail "E2E tests failed. Run '$run test:e2e' to see details."

echo "✅ All pre-push checks passed!"
