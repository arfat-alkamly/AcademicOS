# Copilot instructions for Academic OS

This repository uses a simple Flutter Clean Architecture pattern with encrypted local storage.

## What to know before editing
- Refer to `AGENTS.md` first for architecture and agent conventions.
- Review `ARCHITECTURE.md` and `lib/ROADMAP.md` before making structural changes.
- Keep the presentation layer limited to `domain/usecases` and never import `lib/data/*` directly into `lib/presentation/*`.
- Persisted data must be handled through `lib/data/database/database_helper.dart` and associated datasource/repository classes.

## Key behavior
- `lib/main.dart` wires dependencies and passes `TaskUseCases` into `HomeScreen`.
- The secure DB password is stored in `lib/core/security/secure_storage_service.dart`.
- Legacy files to ignore if encountered: `lib/services/database_helper.dart` and `lib/models/task_model.dart`.

## When to update files
- Add new features by introducing domain entities/interfaces first.
- Update database schema and migration logic in `lib/data/database/database_helper.dart` when persistence changes.
- Prefer small, incremental commits and preserve layer separation.
