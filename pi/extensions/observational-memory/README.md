# Observational memory

This extension lives in its own repository:

**→ [amosblomqvist/pi-observational-memory](https://github.com/amosblomqvist/pi-observational-memory)**

Tiered, subprocess-backed memory for pi. Parallel observers distill the conversation into atomic observations, a consolidator promotes the oldest into durable `.memory/` topic files, and compaction is deterministic and model-free. My own implementation of the observational-memory idea (see [Mastra](https://mastra.ai/docs/memory/observational-memory)).
