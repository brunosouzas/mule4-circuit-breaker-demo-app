# Contributing

Since 2.0.0 there is no `develop`. The workflow decides what happens from the branch and the action, so the branch you choose *is* the instruction ([mulesoft/README.md of github-reusable-workflows](https://github.com/brunosouzas/github-reusable-workflows/blob/main/mulesoft/README.md)).

| Branch or run | Created from | Merges into | What the workflow does |
|---|---|---|---|
| `feature/<ticket>-<desc>` | `main` | `main` (PR) | Build, no secret, no deploy |
| `main` | — | — | SNAPSHOT to Exchange, deploy to **TEST** |
| Run workflow on `main`, action `criar-release` | — | — | `release/X.Y.Z` from the latest tag with the chosen pull requests; the release pull request; the pull request moving `main` to the next minor |
| `release/X.Y.Z` | Criar release | never merged | SNAPSHOT to Exchange, deploy to **UAT** |
| `fix/<ticket>-<desc>` (a defect found in UAT) | `release/X.Y.Z` | `release/X.Y.Z` (PR) | Build; the merge deploys to **UAT** |
| Run workflow on `release/X.Y.Z`, action `release` | — | — | Maven release (tag `vX.Y.Z`), back-merge pull request into `main` |
| tag `vX.Y.Z` | Release | — | Deploy to **UAT**, then to **PROD** after approval; the release branch is deleted |
| `back-merge/vX.Y.Z` | Release, from `main` | `main` (PR, after PROD) | Build; the merge deploys to **TEST** |

A defect in production is a release with one fix: Criar release with no pull requests and the next patch typed as the version, then a pull request into that release.

Merge every pull request squashed, with a message written by hand (one line per change) and no skip-CI marker (`[skip ci]`, `[ci skip]`, `[no ci]`, `[skip actions]`, `[actions skip]`, `skip-checks: true`) anywhere: Criar release and the back-merge pick squash commits, and a marked one deploys nothing.

## Versions

Never edit the version in `pom.xml` by hand: Criar release sets the release's version and moves `main` to the next minor, and the Maven release sets the tag and the release's next patch `-SNAPSHOT`.

## Tests

Run `mvn clean test` before opening a PR: MUnit coverage must stay at or above 80% (`pom.xml`'s `munit-maven-plugin`). MUnit does not run in the public workflow, because it needs the Mule Enterprise runtime and a MuleSoft customer credential, which never goes to a public repository.
