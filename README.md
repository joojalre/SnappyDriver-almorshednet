# Snappy Driver Installer (Almorshednet)

Portable Windows driver maintenance tool focused on:

- scan and detect missing/outdated devices
- select and install drivers safely
- support offline workflows for repair benches / technician environments

## Download

- Official distribution package: [Download SDI from project site](https://github.com/joojalre/SnappyDriver-almorshednet)
- Windows: run `SDIO_x64_*.exe` from extracted package folder (administrator recommended for install flows).

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
