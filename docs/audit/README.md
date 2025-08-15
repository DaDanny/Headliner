# Headliner Cleanup — Main App

This folder contains audit notes and reports for the main app cleanup.

- See `PHASE_0_REPORT.md` for the file inventory and cross-cutting concerns.
- `PHASE_2_PERIPHERY.md` will track dead-code candidates after running Periphery.

Run tools locally:

- Formatting: `swiftformat Headliner`
- Linting: `swiftlint lint --quiet`
- Dead code: `periphery scan --config periphery.yml`

