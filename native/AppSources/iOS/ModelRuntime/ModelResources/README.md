# ModelResources

This folder is the iOS app bundle entry point for local model resources.

Expected future files:

- `gemma-4-E2B-it.litertlm`

Do not commit large or licensed model files until the model distribution policy is explicit. The Core catalog currently points diagnostics at `ModelResources/gemma-4-E2B-it.litertlm`, so DEBUG builds will report this resource as missing until a real LiteRT-LM model package is provided.

Real execution also requires linking the LiteRT-LM Swift package and enabling the `FITNESSRPG_ENABLE_LITERTLM` compile flag. Without both, the iOS adapter remains unavailable and the app uses deterministic fallback copy.
