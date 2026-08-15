# Mission

## Problem Statement
There's no fast way to stand up a Spotify-quality listening experience for a self-hosted / user-generated music catalog. Existing "build your own streaming app" tutorials are either backend-only demos or Flutter UI shells with no real playback, auth, or upload pipeline behind them. This project builds the real thing, full-stack.

## Target User
A single end user of the finished app: someone who signs up and gets a full Spotify-grade experience (browse, search, play, organize) on top of the catalog.

## Value Proposition
A pixel-close, production-grade clone of Spotify — Flutter client, NestJS backend, Postgres — where users authenticate and browse/search/play/organize tracks with the real Spotify UI and interaction model.

## Flags
- **Naming**: "Spotify" is used here only as an internal working title (matches the stakeholder's stated brief). It is a live trademark — do not ship to a public app store or production domain under this name without renaming. Revisit before any public release.
- **Deadline vs. scope**: the stated deadline (next day) does not fit the full feature set at the production bar defined in `engineering-standards.md`. `roadmap.md` phases a real, thin, end-to-end MVP as the deliverable for that deadline; the rest of this document's scope is sequenced in later phases. This is a scope/timeline mismatch flagged for the stakeholder, not silently resolved in either direction.

## Core User Stories
These are the source of truth. Every acceptance criterion in every future feature-spec and validation.md must trace back to one of these (or an explicitly approved later addition to this list) — anything that doesn't is scope creep and should be flagged, not quietly built.

1. **As a new user**, I want to sign up and log in (email/password, or Google/Apple/Facebook), so that I can securely access my account and library from any device.
2. **As a listener**, I want to search for tracks, artists, and albums, so that I can quickly find and play something specific.
3. **As a listener**, I want to browse curated shelves and genre categories on a Home screen, so that I can discover things in my catalog without knowing exactly what I want.
4. **As a listener**, I want full playback controls (play/pause/skip/seek/queue/shuffle/repeat) that persist in the background, so that listening feels seamless and matches the real Spotify experience.
5. **As a user**, I want to create, rename, delete, and reorder playlists, and like individual songs, so that I can organize my library the way I want.

## Judging/Scoring Criteria
N/A — production application, not a hackathon/bounty submission.
