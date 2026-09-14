# tests/fixtures/

This directory is intentionally empty.

## Why

`om4mtools-matlab` is currently a strictly personal project, always run on
machines where the author's Dropbox is present at a known, fixed relative
location. Earlier in Fase 2 all fixture data (~11 GB) was copied into this
directory and fetched on demand with `download_fixtures.sh`, so the test
suite would work for hypothetical other users/machines without direct
access to the author's Dropbox.

That portability isn't needed right now:

- There is no other consumer of this repo yet.
- Any MATLAB test run (including local "CI") always happens on a machine
  where the Dropbox mirror already exists.
- Copying ~11 GB into the repo tree just duplicated data that already
  lives in Dropbox, for no benefit.

## Where the data actually lives

`<dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab`

Resolved via `fixturesRoot()` (`tests/fixturesRoot.m`), which wraps
`dropbox()` (`src/dropbox.m` - locates the local Dropbox root by hostname).
Tests never call `dropbox()` directly; they call `fixturesRoot()`, exactly
as before this change - only what `fixturesRoot()` resolves to changed.

If this project ever gains outside consumers/contributors again, reintroduce
a downloadable/portable fixtures mechanism at that point rather than before.
