# Academic OS AI Agent Guide

## Purpose
This guide helps AI agents understand Academic OS and make safe, architecture-respecting code changes.

## What this repository is
- Flutter app using a lightweight Clean Architecture style.
- Uses SQLite through `sqflite`; the database file is **not currently encrypted at rest**. `flutter_secure_storage` protects selected secrets and preferences only.
- Focuses on task management in the UI, with early course support in the data/domain layers.

## Core architecture
- `lib/core/`: shared services and security helpers.
- `lib/domain/`: entities, repository interfaces, and use case classes.
- `lib/data/`: storage models, local data sources, repository implementations, and database helper.
- `lib/presentation/`: UI screens and widgets.

## Layer rules
- `presentation` speaks only to `domain/usecases`.
- Do not import `lib/data/*` directly into `lib/presentation/*`.
- Persistence changes should go through:
  - `lib/data/models`
  - `lib/data/datasources`
  - `lib/data/repositories`
  - `lib/data/database`
- Keep secure storage logic centralized in `lib/core/security/secure_storage_service.dart`.

## Important files
- `lib/main.dart` — dependency composition and app bootstrap.
- `lib/core/security/secure_storage_service.dart` — secure DB password management.
- `lib/data/database/database_helper.dart` — SQLite database helper and schema migrations (not SQLCipher).
- `lib/data/datasources/task_local_data_source.dart` — task local datasource.
- `lib/data/repositories/task_repository_impl.dart` — task repository implementation.
- `lib/domain/usecases/task_use_cases.dart` — task use cases.
- `lib/presentation/home/home_screen.dart` — home screen for task list.
- `lib/presentation/task/add_edit_task_screen.dart` — add/edit task screen.

## Existing support beyond task UI
- Course entities, models, data sources, repositories, and use cases exist.
- The current UI does not yet expose course management.

## Best agent behavior
- Review `ARCHITECTURE.md` and `lib/ROADMAP.md` before making structural changes.
- Prefer small, incremental edits.
- Add new domain interfaces before changing data or presentation.
- Preserve layer separation and avoid cross-layer imports.

## Notes
- `pubspec.yaml` now exists, so package changes should go there.
- If storage structure changes, update migrations in `lib/data/database/database_helper.dart`.
- Ignore legacy files if encountered: `lib/services/database_helper.dart` and `lib/models/task_model.dart`.
