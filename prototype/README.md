# Fitness RPG Interactive Prototype

This dependency-free browser prototype aligns the Fitness RPG Today Command Center before native iPhone/watchOS development.

## Open

Open directly:

```text
prototype/index.html
```

Or serve locally:

```bash
cd prototype
python3 -m http.server 5173
```

Then open `http://localhost:5173`.

## What To Test

- Switch Green / Yellow / Red readiness scenarios.
- Confirm quest intensity changes with readiness.
- Confirm Safety Validator blocks unsafe framing on Yellow and Red days.
- Preview the Apple Watch execution payload.
- Switch model mode between Local Only, Local + Remote Enhancement, and Remote Disabled.
- Complete a mock workout and inspect the recap.
