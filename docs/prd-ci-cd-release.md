## Problem Statement

The app currently builds and runs locally through SwiftPM and ad hoc shell scripts, but it does not have a repository-managed delivery pipeline. There is no hosted CI to prove that pull requests still build and pass tests, no standard release workflow for version tags, and no repeatable way to package artifacts for GitHub releases. The user wants the repo to support a proper CI/CD foundation so the project can be developed with confidence now and upgraded later to a standard signed and notarized public release flow.

## Solution

Add a GitHub Actions based macOS delivery pipeline with two immediate outcomes. First, every pull request and main-branch change should run a narrow CI workflow that builds the app and runs the existing automated tests on a macOS runner. Second, version tags should trigger a release workflow that packages the app into a standard downloadable artifact for GitHub Releases, publishes that artifact with auto-generated release notes, and validates the packaging path even before Apple signing credentials exist. The release design should explicitly preserve a later path to replace unsigned packaging with Developer ID signing, notarization, and stapling without having to redesign the entire pipeline.

## User Stories

1. As a maintainer, I want every pull request to run on GitHub Actions, so that I know whether the app still builds before merging.
2. As a maintainer, I want CI to run on macOS, so that the build environment matches the app’s actual platform.
3. As a maintainer, I want CI to run the current automated tests, so that geometry and state regressions are caught automatically.
4. As a maintainer, I want the CI workflow to stay intentionally narrow at first, so that the pipeline is reliable and easy to debug.
5. As a maintainer, I want the repository to define build and test entry points explicitly, so that local verification and hosted CI use the same commands.
6. As a maintainer, I want failures in build or tests to block confidence in a change, so that broken code is not merged casually.
7. As a maintainer, I want release automation to start from version tags, so that public releases happen intentionally rather than on every merge.
8. As a maintainer, I want a tagged release to produce a packaged app artifact automatically, so that I do not have to assemble releases by hand.
9. As a maintainer, I want release artifacts attached to GitHub Releases, so that users have a predictable download location.
10. As a maintainer, I want GitHub Release notes to be auto-generated, so that publishing a release does not require manual changelog writing.
11. As a maintainer, I want the release artifact format to match common macOS expectations, so that future public distribution feels conventional.
12. As a maintainer, I want the packaging workflow to be reproducible from repository scripts, so that release troubleshooting does not depend on undocumented manual steps.
13. As a maintainer, I want the release pipeline to work before signing is introduced, so that CI/CD progress does not stall on Apple account setup.
14. As a maintainer, I want the unsigned release path to be clearly identified as an interim state, so that later signing work does not get forgotten or confused with a final public-distribution solution.
15. As a maintainer, I want the packaging job to validate the app bundle structure, so that broken release artifacts are caught before publishing.
16. As a maintainer, I want repository secrets and signing inputs to be absent from the first phase, so that the initial setup remains free and simple.
17. As a maintainer, I want the future signing and notarization hooks designed in advance, so that the pipeline can evolve without a rewrite.
18. As a maintainer, I want release automation separated from PR CI, so that routine validation stays fast and releases can add heavier packaging steps.
19. As a maintainer, I want workflow responsibilities split into small modules and scripts, so that each part of the delivery system is testable and maintainable.
20. As a maintainer, I want the project to remain SwiftPM-first for normal development, so that local iteration stays lightweight.
21. As a maintainer, I want release packaging to use the standard macOS archive/export path rather than only ad hoc file copying, so that the project is aligned with the future signed distribution model.
22. As a maintainer, I want a documented versioning and release trigger convention, so that anyone working on the repo knows how to cut a release.
23. As a maintainer, I want manual smoke-style validation to remain possible outside CI, so that platform behaviors not covered by unit tests can still be checked before publishing.
24. As a future releaser, I want the pipeline to support adding signing, notarization, and DMG hardening later, so that the repo can move from free CI to standard public distribution cleanly.
25. As a user downloading the app from GitHub, I want the artifact to be easy to identify and install, so that the release experience is straightforward even before signing exists.
26. As a developer, I want delivery logic isolated from app feature code, so that product changes and release engineering changes do not become entangled.
27. As a developer, I want workflow outcomes and artifact names to be deterministic, so that debugging release failures is simpler.
28. As a developer, I want the repo to document the limitations of unsigned releases, so that team expectations stay accurate until paid Apple credentials are added.

## Implementation Decisions

- GitHub Actions will be the delivery platform for both CI and release workflows.
- The initial CI surface will run only on macOS runners.
- Pull request CI will validate only build and automated tests in the first phase. Packaging and release publication remain outside normal PR validation.
- The project should keep SwiftPM as the primary local development workflow for build and tests.
- Release automation should be triggered by version tags using a documented tag convention such as `vX.Y.Z`.
- Release automation should create a GitHub Release with automatically generated release notes.
- The initial public artifact should be a DMG attached to the GitHub Release, because that is the conventional long-term distribution target for this app class.
- In the free first phase, that DMG will contain an unsigned app and must be treated as an interim artifact rather than a final trusted-distribution solution.
- The release workflow should produce the app through a packaging path that can evolve into the standard signed distribution process later, rather than baking in a dead-end unsigned-only approach.
- The repo should introduce a dedicated packaging module or script layer that owns archive assembly, export preparation, artifact naming, and validation separately from the existing run helper scripts.
- The current ad hoc bundle-copy script is acceptable as prior art, but release packaging should move toward a standard archive/export oriented flow that can later absorb signing and notarization steps.
- CI and release concerns should be separated into distinct workflow modules so that PR feedback stays fast and release jobs can grow more sophisticated over time.
- The pipeline should be designed so that future signing integration is additive: inject certificates, provisioning inputs if needed, notarization credentials, and stapling steps without redefining version triggers or artifact publication.
- The future signing path should target Developer ID distribution outside the Mac App Store, not App Store packaging.
- The repo should document that proper public trusted distribution later requires paid Apple Developer Program access for Developer ID signing and notarization.
- A release-preparation interface should define the minimum required inputs for publishing: version tag, artifact name, bundle metadata, and packaging output location.
- A workflow-facing validation interface should define the minimum CI contract: build succeeds and tests pass on a clean macOS runner.
- Delivery-specific configuration should live in workflow files and packaging scripts, not in general app state modules.
- Bundle metadata such as bundle identifier, version, and minimum system version should have a single authoritative source or a clearly defined generation path so archive and release jobs do not drift from the app’s real identity.
- The implementation should favor deep modules over scattered shell snippets. A narrow packaging component should hide archive/export details behind a simple entry point, and a narrow release-publication component should hide GitHub artifact assembly behind a stable interface.
- Manual smoke testing remains a supplementary pre-release activity rather than a mandatory GitHub Actions gate in the first phase.

## Testing Decisions

- A good test for this work validates externally observable delivery behavior rather than internal workflow implementation details. The important outcomes are whether the app builds, whether automated tests pass, whether a tagged release emits the expected artifact, and whether the artifact structure is valid.
- The CI contract itself should be validated through repository commands that developers can run locally before relying on GitHub Actions.
- The packaging module should be tested through behavioral checks such as artifact existence, deterministic naming, bundle structure correctness, and failure on missing required inputs.
- Existing app unit tests remain the primary automated product-level signal in PR CI. The current prior art is the repository’s `swift test` based suite covering overlay geometry and state reduction behavior.
- Existing local smoke-test scripts are prior art for manual end-to-end verification and should remain available as manual release confidence checks outside required PR CI.
- Workflow verification should focus on observable job outcomes rather than brittle assertions about individual shell implementation steps.
- Future signing-phase tests should validate signed bundle verification, notarization success, and stapled artifact inspection, but those checks are deferred until Apple credentials exist.
- Documentation should explicitly distinguish three confidence levels: PR CI build/test validation, tagged release packaging validation, and optional manual pre-release smoke verification.

## Out of Scope

- Developer ID signing, notarization, stapling, or any other paid Apple Developer Program dependent capability.
- Mac App Store submission or App Store Connect workflows.
- Auto-update integration such as Sparkle.
- Cross-platform CI runners or non-macOS distribution.
- Mandatory smoke-test execution inside GitHub Actions.
- Advanced release governance such as approval environments, staged rollouts, or release promotion.
- Broader app architecture changes unrelated to build, packaging, and release engineering.
- A promise that unsigned GitHub releases provide the normal trusted macOS install experience.

## Further Notes

- This PRD intentionally treats delivery as a phased system. The first phase buys confidence and repeatability for development without requiring paid Apple credentials.
- The release packaging design should avoid cornering the repo into a custom unsigned-only path. The correct long-term goal remains a signed and notarized outside-App-Store release flow once the project is ready to pay for Apple Developer Program access.
- If the team later wants a public polished distribution experience, the signing phase should be framed as enabling the standard trust path rather than as an optional cosmetic improvement.
