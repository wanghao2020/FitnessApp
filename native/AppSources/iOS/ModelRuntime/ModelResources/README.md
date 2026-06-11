# ModelResources

This folder is the iOS app bundle entry point for local model resources.

Expected future files:

- `gemma-e2b.task`
- `tokenizer.model`

Do not commit large or licensed model files until the model distribution policy is explicit. The Core catalog currently points diagnostics at `ModelResources/gemma-e2b.task` and `ModelResources/tokenizer.model`, so DEBUG builds will report these resources as missing until real files are provided.
