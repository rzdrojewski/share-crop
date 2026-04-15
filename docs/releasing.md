# Releasing

## CI

The repository CI entry point is:

```bash
./script/ci.sh
```

This is the same command used by GitHub Actions on pull requests and pushes to `main`.

## Release Trigger

Unsigned public releases are created from Git tags that match the `vX.Y.Z` convention.

Example:

```bash
git tag v0.1.0
git push origin v0.1.0
```

That tag triggers the release workflow on GitHub Actions, which will:

1. build the macOS app bundle
2. package an unsigned DMG
3. validate the bundle and DMG structure
4. create a GitHub Release
5. generate release notes automatically

## Local Packaging

You can build the release artifact locally with:

```bash
./script/package_release.sh --version 0.1.0 --artifact-version v0.1.0
```

The generated DMG will be written to:

```text
dist/release/ScreenShare-v0.1.0-unsigned.dmg
```

## Unsigned Release Limitations

Phase 1 releases are intentionally unsigned. This keeps the setup free, but it is not the standard trusted macOS distribution path.

Users should expect Gatekeeper friction, including warnings that the app is from an unidentified developer. This is acceptable for the current phase, but it is not the final public-distribution experience.

The later signing phase will replace this with `Developer ID` signing, notarization, and stapling once Apple credentials are available.
