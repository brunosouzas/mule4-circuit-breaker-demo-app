# mule4-circuit-breaker-demo-app: project context

## Purpose

A Mule 4 application that uses the [mule4-circuit-breaker](https://github.com/brunosouzas/mule4-circuit-breaker) plugin against a simulated backend you can make fail, slow down or recover, so each circuit breaker scenario can be triggered and checked inside a real Mule runtime.

## Technology

Stack: Mule 4, MUnit, Maven, GitHub Actions, CloudHub 2.0
Delivery: C environments
Integration branch: `main`
Data: none
Article: `50-writing/circuit-breaker-in-mulesoft/`

- Build: `mvn -B clean package -DskipMunitTests` (needs an anypoint-exchange-v3 server entry in ~/.m2/settings.xml for the plugin, see README.md)
- Test: `mvn clean test` (MUnit; needs the MuleSoft Enterprise repository credentials)
- Run locally: `mvn clean package`, run it on a local Mule runtime and use the curl calls in README.md against localhost:8081
- Deliver and verify: `.github/workflows/delivery.yml` (the reusable `mulesoft-app.yml` of github-reusable-workflows, pinned by SHA): a merge into `main` deploys TEST; Criar release opens `release/X.Y.Z`, which deploys UAT; Release makes the tag, whose run deploys UAT and then PROD after Bruno's approval; each deploy job checks the application RUNNING the version and `GET /health` 200; then the back-merge pull request into `main`

## Technology declarations

- `app.runtime = 4.9.17` — [pom.xml](pom.xml).
- `mule.maven.plugin.version = 4.9.1` — [pom.xml](pom.xml).
- `munit.version = 3.7.1` — [pom.xml](pom.xml).
- `mule.http.connector.version = 1.11.3` — [pom.xml](pom.xml).
- `mule.scripting.module.version = 2.1.1` — [pom.xml](pom.xml).
- `Declared minimum Mule runtime 4.9.0` — [mule-artifact.json](mule-artifact.json).

These are source declarations, not evidence of installed runtimes. Maven properties may describe build/test dependencies rather than supported runtime minima; unresolved expressions remain inherited until verified.

## Layout and operation sources

Top-level source/documentation directories: `src`.

- [README.md](README.md).
- [mule-artifact.json](mule-artifact.json).
- [pom.xml](pom.xml).

GitHub default branch inspected on 2026-10-06: `main`. Release bases are defined by the project sources, separately from that setting. Build/publish commands mentioned by those sources are context, not authorization.

## Project rules

Before planning, reviewing or changing this project, read [the applicable project rules](rules/README.md).

- Article repository: this repository was made for a published article and keeps what the article published (its code, branches and pipeline). A change here changes the article, so every merge is Bruno's (level 2), also under a delegation.
- Tracker: Linear brunosouzas, team SW, label mulesoft.
- OpenSpec: no: every change takes the small path.
- Branches since 2.0.0: a change is a pull request from `feature/sw-<n>-<slug>` into `main`; a UAT fix is a pull request into the open `release/X.Y.Z`; squash merges with a message written by hand and no skip-CI marker. Criar release, Release and PROD are Bruno's runs. The 1.x history keeps the Azure DevOps GitFlow pipeline the first article describes.
