# ModelResources

This folder is the iOS app bundle entry point for local model resources.

Expected future files:

- `gemma-4-E2B-it.litertlm`

Do not commit large or licensed model files until the model distribution policy is explicit. The Core catalog currently points diagnostics at `ModelResources/gemma-4-E2B-it.litertlm`, so DEBUG builds will report this resource as missing until a real LiteRT-LM model package is provided.

Use `model-package-manifest.example.json` to record the expected package name, bundle path, minimum byte size, license/source notes, and checksum outside git before handing a real model package between machines.

Real execution also requires linking the LiteRT-LM Swift package and enabling the `FITNESSRPG_ENABLE_LITERTLM` compile flag. Without both, the iOS adapter remains unavailable and the app uses deterministic fallback copy.

Before real-device validation, run the local checklist and preflight from the repository root:

```bash
bash native/scripts/litertlm-integration-checklist.sh
```

```bash
bash native/scripts/litertlm-real-device-preflight.sh
```

After adding the licensed model package, LiteRT-LM Swift package, and compile flag, rerun:

```bash
bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime
```

Then follow `docs/validation/litertlm-real-device-runbook.md`.
