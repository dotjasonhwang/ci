# ci

Shared CI workflows and git hooks for the dotjasonhwang sites. The workflows run in the
calling repo, so checkout, `.nvmrc` and the lockfile come from the site.

## Setup

Each site installs this repo as a devDependency. The pre-push hook and `link-check.yml` both
read the shared lychee settings from it.

```sh
pnpm add -D github:dotjasonhwang/ci#v1
```

Add `.lycheecache` to the site's `.gitignore`.

The lockfile pins a commit, so moving `v1` updates the workflows right away, but the hook and
`lychee.toml` only after `pnpm update @dotjasonhwang/ci`.

## `site-ci.yml`

Check, unit test and build on push and PRs; Playwright E2E on PRs and manual runs.

| Input             | Type    | Default | Description                                              |
| ----------------- | ------- | ------- | -------------------------------------------------------- |
| `package-manager` | string  | `pnpm`  | `pnpm` or `npm`                                          |
| `run-check`       | boolean | `true`  | Run `<package-manager> run check` (astro check + eslint + prettier) |

## `link-check.yml`

Builds the site, then checks every link in `dist/` with lychee: internal links resolve against
`dist/`, external ones are fetched. Settings come from `lychee.toml`; the site's own domain
(from its sitemap) is skipped.

| Input             | Type   | Default | Description                                                     |
| ----------------- | ------ | ------- | --------------------------------------------------------------- |
| `package-manager` | string | `pnpm`  | `pnpm` or `npm`                                                 |
| `extra-args`      | string | `''`    | Extra lychee arguments, one per line (e.g. `--exclude some-domain.com`) |

```yaml
jobs:
  ci:
    uses: dotjasonhwang/ci/.github/workflows/site-ci.yml@v1
    with:
      package-manager: pnpm
  links:
    uses: dotjasonhwang/ci/.github/workflows/link-check.yml@v1
```

## Pre-push hook

`djh-pre-push` runs check, unit tests, build, an internal-only link check and E2E, stopping
at the first failure. External links are left to `link-check.yml`. It needs
[lychee](https://lychee.cli.rs) (`brew install lychee`). In `.husky/pre-push`:

```sh
pnpm exec djh-pre-push               # or `npx djh-pre-push` in npm repos
pnpm exec djh-pre-push --skip-check  # sites whose `check` script doesn't pass yet
```
