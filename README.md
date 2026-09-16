# Receipt Mgr (camera2image)

An app that captures receipt images, optionally converts them to black and white, and saves them locally.

# AI tool used
Cursor used with Claude Opus 5



![Receipt Mgr screenshot](https://github.com/user-attachments/assets/3d83e6bc-3c99-4949-b9f88978ba55e)

## Features

- Camera capture with optional black-and-white conversion
- Local draft storage
- Company switching for multi-tenant receipts - Use the hamburger menu.
- View locally cached data from the hamburger menu

## flutter_secure_storage

Sensitive persisted data uses `flutter_secure_storage`.

### Infrastructure

- `lib/services/storage/secure_storage_service.dart` — shared wrapper with typed keys:
  - `company_id`
- `lib/modules/company/repository/company_storage.dart` — stores company ID securely, with one-time migration from SharedPreferences

### Usage

| Area | Change |
| --- | --- |
| CompanyBloc | Reads and writes company ID via `CompanyStorage` |
| SaveScreen | Loads company ID from `CompanyStorage` |

### Not stored in secure storage

- **HydratedBloc drafts** — local receipt metadata and file paths (not auth secrets)

Existing SharedPreferences company IDs are migrated automatically on first read, then removed from prefs.


** Automated integration test added.
