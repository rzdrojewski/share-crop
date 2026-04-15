# Plan: CI/CD And Release Delivery

> Source PRD: [docs/prd-ci-cd-release.md](../docs/prd-ci-cd-release.md)

## Architectural decisions

Durable decisions that apply across all phases:

- **Delivery platform**: GitHub Actions is the single CI/CD platform for pull request validation and tagged releases.
- **Runner scope**: Only macOS runners are in scope.
- **Trigger model**: Pull requests validate build and tests. Version tags using the `vX.Y.Z` convention trigger release publication.
- **Development workflow**: SwiftPM remains the primary local build and test workflow for day-to-day development.
- **Release artifact**: The public downloadable artifact is a DMG attached to a GitHub Release.
- **Release notes**: GitHub Release notes are auto-generated.
- **Distribution path**: Phase 1 ships unsigned public artifacts as an interim delivery path. Phase 2 upgrades that same pipeline to Developer ID signing, notarization, and stapling.
- **Packaging direction**: Release packaging should evolve toward a standard macOS archive/export style flow rather than remain a purely ad hoc copy-script path.
- **Testing strategy**: Required CI covers build and automated tests. Manual smoke verification remains supplemental outside the required PR gate.
- **Future trust model**: Proper trusted public distribution depends on paid Apple Developer Program access and is intentionally deferred to the signing phase.

---

## Phase 1: Unsigned CI And Public Releases

**User stories**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 18, 20, 21, 22, 23, 25, 26, 27, 28

### What to build

Create a complete free delivery path that works end-to-end. Pull requests and main-branch changes should run GitHub Actions build and test validation on macOS. Version tags should trigger a release workflow that packages the app into a deterministic unsigned DMG, validates the bundle and artifact structure, publishes the artifact to GitHub Releases, and generates release notes automatically. The repository should document both the release trigger convention and the limitations of unsigned macOS distribution.

### Acceptance criteria

- [x] Pull requests run a GitHub Actions workflow on macOS that builds the app and runs the existing automated tests.
- [x] The CI workflow uses repo-supported commands that can also be run locally.
- [x] Pushing a version tag matching the documented convention creates a GitHub Release automatically.
- [x] The release workflow produces a deterministic unsigned DMG artifact containing the app.
- [x] The release workflow validates the generated bundle and artifact structure before publishing.
- [x] The published GitHub Release includes auto-generated release notes.
- [x] The repo documents how to trigger releases and clearly states the user-facing limitations of unsigned distribution.

---

## Phase 2: Signed And Notarized Distribution Upgrade

**User stories**: 14, 16, 17, 24

### What to build

Upgrade the existing tagged release path so it becomes the standard outside-App-Store distribution flow for macOS. The workflow should consume Apple signing and notarization credentials, sign the app for Developer ID distribution, notarize the release artifact, staple the resulting ticket, and publish the trusted artifact through the same GitHub Release mechanism introduced in Phase 1. This phase should be additive rather than a redesign of the unsigned pipeline.

### Acceptance criteria

- [ ] The release pipeline accepts the required Apple signing and notarization secrets without changing the tag-based release model.
- [ ] Tagged releases sign the app for Developer ID distribution.
- [ ] Tagged releases complete notarization successfully and staple the resulting ticket to the shipped artifact.
- [ ] The signed artifact replaces the unsigned interim artifact while preserving deterministic naming and GitHub Release publication.
- [ ] The repo documents the required Apple account setup, secrets, and release-operating procedure for the trusted distribution path.
