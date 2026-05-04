# Releasing ElevenClock

This document describes how to publish a new release of ElevenClock from this fork. The flow is tag-driven and
fully automated by GitHub Actions — there is no manual upload step.

## TL;DR

```powershell
# 1. Bump version in elevenclock/versions.py (three lines)
# 2. Commit and push to main
git add elevenclock/versions.py
git commit -m "Release 4.4.1.2"
git push origin main

# 3. Tag the release commit and push the tag
git tag 4.4.1.2
git push --tags
```

Two workflows (`Build x64` and `Build ARM64`) fire on the tag push, build their installers, and attach them to a
freshly-created GitHub Release named `ElevenClock 4.4.1.2`.

## Step-by-step

### 1. Bump the version

Edit `elevenclock/versions.py`. All three values must match:

```python
version = 4.412
versionName = "4.4.1.2"
versionISS = "4.4.1.2"
```

`build_ci.cmd` runs `scripts/apply_versions.py` during CI, which stamps `versionISS` into `ElevenClock.iss` and the
PyInstaller version-info resource. You do not need to edit those files by hand.

### 2. Commit and push

```powershell
git add elevenclock/versions.py
git commit -m "Release 4.4.1.2"
git push origin main
```

### 3. Tag and push the tag

```powershell
git tag 4.4.1.2
git push --tags
```

Tag names must match the regex pattern `[0-9]*` (defined in the workflow `push.tags` filter). Pure-numeric version
strings like `4.4.1.2` work; `v4.4.1.2` would not trigger the workflows.

### 4. CI builds and publishes

The moment the tag lands on GitHub, both workflows start in parallel. Each takes roughly 5 minutes.

Per workflow:

1. Checkout the tag.
2. `build_ci.cmd` builds the PyInstaller bundle into `ElevenClockBin/`.
3. The runner's preinstalled Inno Setup 6.7.1 compiles `ElevenClock.iss` into `ElevenClock.Installer.x64.exe` or
   `ElevenClock.Installer.arm64.exe`.
4. `softprops/action-gh-release@v3` creates (or updates) the release for tag `4.4.1.2` and uploads the installer.

The first workflow to finish creates the release with auto-generated notes from PRs and commits since the previous
tag. The second workflow appends its installer to the same release.

### 5. Watch the runs

```powershell
gh run watch
gh run list --workflow=build-x64.yml --limit 1
gh run list --workflow=build-arm64.yml --limit 1
```

Or browse to the Actions tab on GitHub.

When both runs are green, the release page shows:

- `ElevenClock.Installer.x64.exe`
- `ElevenClock.Installer.arm64.exe`
- Source code zip and tarball (added automatically by GitHub)

## Recovering from failure

If a workflow fails after the release was created, the release stays published with whatever installers did make it.
You have a few options:

- **Re-run the failed workflow:** `gh run rerun <run-id>` — the rerun will reattach its installer to the existing
  release.
- **Push a fix and re-tag:** if the bug is in the source, fix it on `main`, then either move the tag
  (`git tag -f 4.4.1.2 && git push --tags --force`) or cut a new patch release (`4.4.1.3`). Moving a tag is fine
  before anyone has downloaded the release; otherwise prefer a new patch.
- **Manual trigger:** both workflows expose `workflow_dispatch`, so you can re-run either one against `main` or any
  branch from the Actions tab. Note that a manual dispatch will not attach to a release (the attach step is gated on
  `startsWith(github.ref, 'refs/tags/')`).

## Important caveats

### `paths` filter applies to tag pushes too

The workflow `push` trigger has a `paths` filter (`**.py`, `requirements.txt`, `build_ci.cmd`,
`elevenclock/elevenclock.spec`, `ElevenClock.iss`, the workflow file itself). For a tag push to fire the workflow,
the commit the tag points to must include a change to one of those paths.

In practice, a release-tagged commit will always be the version bump in `elevenclock/versions.py` (matches `**.py`),
so this works. If you ever need to tag a commit that does not touch those paths, run the workflows via
`workflow_dispatch` instead.

### Installers are not code-signed

CI does not sign the binaries. First-time downloaders will see a SmartScreen warning and need to click
**More info → Run anyway**. Wiring up signing requires a code-signing certificate stored in GitHub Secrets and a
`signtool` step before the Inno Setup compile — out of scope for this document.

### `winget-release.yml`

The upstream-inherited `winget-release.yml` workflow fires on `release: released` and tries to submit the new
version to Winget using `secrets.WINGET_TOKEN`. On a fork without that secret it will fail noisily but harmlessly.
Disable it on your fork if the failure notifications are annoying.

### Source-code archives are auto-attached

GitHub itself attaches `Source code (zip)` and `Source code (tar.gz)` to every release. You cannot opt out of this
without using a draft release flow.

## What the workflows do not do

- They do not build the local maintainer installer named `ElevenClock.Installer.exe` (without arch suffix). That is
  the upstream maintainer's manual local-build artefact (`build.cmd` + Inno Setup on the dev machine). This fork's
  CI produces the suffixed `.x64`/`.arm64` installers only.
- They do not generate a custom changelog from `RELEASE.md`. Auto-generated GitHub release notes are used instead.
  If you need the upstream `RELEASE.md` template, run `build.cmd --release` locally — it writes the file but does
  not publish it anywhere.
- They do not push to Winget. That is what the separate `winget-release.yml` workflow does (and only on the upstream
  account).
