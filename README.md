# ci

Reusable GitHub Actions workflows shared by the sites. They run in the calling
repo, so checkout, `.nvmrc` and the lockfile come from the site.

## `site-ci.yml`

Check, unit test and build on push and PRs; Playwright E2E on PRs and manual runs.

| Input             | Type    | Default | Description                                              |
| ----------------- | ------- | ------- | -------------------------------------------------------- |
| `package-manager` | string  | `pnpm`  | `pnpm` or `npm`                                          |
| `run-check`       | boolean | `true`  | Run `<package-manager> run check` (astro check + eslint + prettier) |

## `link-check.yml`

Builds and serves the site, then checks links in it and in `./src/` with lychee.

| Input             | Type   | Default | Description                                                     |
| ----------------- | ------ | ------- | --------------------------------------------------------------- |
| `package-manager` | string | `pnpm`  | `pnpm` or `npm`                                                 |
| `extra-args`      | string | `''`    | Extra lychee arguments, one per line (e.g. `--exclude some-domain.com`) |

## Usage

```yaml
jobs:
  ci:
    uses: dotjasonhwang/ci/.github/workflows/site-ci.yml@v1
    with:
      package-manager: pnpm
  links:
    uses: dotjasonhwang/ci/.github/workflows/link-check.yml@v1
```
