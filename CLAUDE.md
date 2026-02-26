# Alfal Mobile - Claude Code Instructions

## Project Overview
Flutter mobile app for Alfal-Co's ERPNext v16 system (w.alfal.co).
Distribution company (poultry) with field sales reps, 5 branches.

## Architecture
- **Framework**: Flutter 3.x (Dart)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **API**: Frappe/ERPNext REST API via Dio
- **Local Storage**: Hive (offline data)
- **AI**: Claude API (Anthropic)

## ERPNext Backend
- URL: https://w.alfal.co
- Version: ERPNext v16.7.0, Frappe v16.10.1
- n8n: https://w.alfal.co:5443

## Key Rules
1. All API calls go through `lib/core/api/` - never call APIs directly from UI
2. Arabic RTL support is mandatory - test both directions
3. Offline-first: cache all read data, queue all writes
4. Follow existing ERPNext DocType field names for models
5. Keep sensitive data (API keys, tokens) in environment config, never hardcode

## Project Structure
```
lib/
├── main.dart           # Entry point
├── app/                # App config, routes, theme
├── core/               # Shared infrastructure
│   ├── api/            # ERPNext API client
│   ├── auth/           # Authentication provider
│   ├── offline/        # Sync engine
│   └── config/         # Environment config
├── features/           # Feature modules (dashboard, sales, etc.)
└── shared/             # Shared widgets, models, utils
```

## Conventions
- Feature folders: `feature_name/` with `view/`, `provider/`, `model/`
- File naming: `snake_case.dart`
- Class naming: `PascalCase`
- Use `freezed` for immutable models
- Use `riverpod_generator` for providers
