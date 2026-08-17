# Snappy Driver Installer (Almorshednet)

Portable Windows driver maintenance tool focused on:

- scan and detect missing/outdated devices
- select and install drivers safely
- support offline workflows for repair benches / technician environments

## Download

- Official distribution package: [Download SDI from project site](https://github.com/joojalre/SnappyDriver-almorshednet)
- Windows: run `SDIO_x64_*.exe` from extracted package folder (administrator recommended for install flows).
- SDIO community fix pack (latest): [v1.1.2](https://github.com/joojalre/SnappyDriver-almorshednet/releases/tag/v1.1.2-sdio-locale-fix-pack)

## What this repository contains

- `README.md`: project overview
- `profile/README.md`: user-facing landing/project description
- `community-fixes/sdio-locale-driver-fix/`: reusable evidence-based fix pack and usage notes contributed from real-world troubleshooting

## Want to contribute a fix?

1. Fork the repo
2. Add your changes
3. Create a pull request against `main`

If your fix is about SDIO run behavior, include:
- reproducible evidence (logs or command output)
- exact machine context (Windows version / SDIO version / device symptoms)
- what changes and why

### Public upstream handoff package

- Latest handoff package (Arabic + English): [UPSTREAM-HANDOFF.md](./community-fixes/sdio-locale-driver-fix/UPSTREAM-HANDOFF.md)
- Official upstream request thread: [Snappy-Driver-Download/.github issue #1](https://github.com/Snappy-Driver-Download/.github/issues/1)

### Feature request channel

This repository keeps issues disabled, so feature requests should be sent as PRs with a documented proposal.

- Proposed UI request (Scan / Re-Scan / Update): [FEATURE_REQUEST_UI_BUTTONS.md](./FEATURE_REQUEST_UI_BUTTONS.md)
