# mule4-circuit-breaker-demo-app: project context

## Purpose

A Mule 4 application that uses the [mule4-circuit-breaker](https://github.com/brunosouzas/mule4-circuit-breaker) plugin against a simulated backend you can make fail, slow down or recover, so each circuit breaker scenario can be triggered and checked inside a real Mule runtime.

## Technology

Stack: Mule 4, MUnit, Maven, Azure Pipelines, CloudHub 2.0
Delivery: C environments
Integration branch: `develop`
Data: none
Article: `50-writing/circuit-breaker-in-mulesoft/`

- Build: `mvn -B clean package -DskipMunitTests` (needs an anypoint-exchange-v3 server entry in ~/.m2/settings.xml for the plugin, see README.md)
- Test: `mvn clean test` (MUnit; needs the MuleSoft Enterprise repository credentials)
- Run locally: `mvn clean package`, run it on a local Mule runtime and use the curl calls in README.md against localhost:8081
- Deliver and verify: `a merge into develop runs the Azure Pipelines GitFlow template (azure-devops-mulesoft-pipelines, pinned tag): build, publish x.y.z-SNAPSHOT to Exchange, deploy to test; a release/x.y.z pull request into main runs the Maven release; verify GET /health in each environment reached answers with that environment's name (URLs in README.md)`

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
- Board area: `mulesoft` (Azure Boards, project `brunosouzas`).
- OpenSpec: no: every change takes the small path.
- Branches follow GitFlow as published: changes go to `develop`; `main` only through a `release/` or `hotfix/` pull request, because a merge into `main` runs the Maven release.
