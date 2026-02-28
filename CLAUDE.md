# alfal-mobile

## Purpose
تطبيق الموظفين (PWA + Mobile) لشركة الفال قوت للتجارة.
يعمل كواجهة للموظفين للوصول لـ ERPNext عبر API — لا يتصل بأي خدمة أخرى مباشرة.

## Architecture
```
alfal-mobile/
├── lib/
│   ├── main.dart                    Entry point
│   ├── app/                         App config, routes, theme
│   ├── core/
│   │   ├── api/                     ERPNext API client (Dio)
│   │   ├── auth/                    Authentication provider
│   │   ├── offline/                 Sync engine (offline-first)
│   │   └── config/                  Environment config
│   ├── features/                    Feature modules (dashboard, sales, etc.)
│   └── shared/                      Shared widgets, models, utils
├── web/                             PWA config
├── assets/                          Images, icons
├── ios/ macos/ android/             Native shells
└── CLAUDE.md                        أنت هنا
```

**Stack**: Flutter 3.x | Dart | Riverpod | GoRouter | Dio | Hive

**Full architecture**: https://github.com/Alfal-Co/alfal-platform → `docs/vision/ALFAL-PLATFORM-VISION.md`

## How to Run
```bash
# تطوير محلي
flutter run -d chrome                # PWA في المتصفح
flutter run                          # جهاز متصل

# بناء PWA
flutter build web --release

# النشر (يُرفع لـ السيرفر عبر pwa.yaml)
# يُنشر على app.alfal.co خلف Traefik
```

## Env / Secrets Policy
```
⛔ ممنوع: API keys في الكود أو assets
✅ مسموح: environment config (compile-time vars)
📍 الاستيثاق: session cookies من ERPNext (لا API keys في المتصفح)
📍 AI API key: server-side فقط (لا يظهر في التطبيق)
```

## Integrations

| يتكامل مع | العلاقة |
|-----------|---------|
| **ERPNext** (w.alfal.co) | API الوحيد — كل القراءة والكتابة عبره |
| **alfal_compat** | APIs مخصصة (WhatsApp proxy, Admin Console) |
| **alfal-platform** | يُنشر عبر gitops/pwa.yaml |

**القاعدة الذهبية**: المتصفح → ERPNext API → الخدمة الخارجية. التطبيق لا يتصل بـ Evolution/n8n/Uptime Kuma مباشرة.

## Current Status
- **الدومين**: https://app.alfal.co (PWA خلف Traefik)
- **ERPNext**: v16 على w.alfal.co
- **State**: Riverpod
- **Offline**: Hive cache
- **RTL**: مدعوم (عربي)

## Next Steps
- ربط WhatsApp Session عبر ERPNext API (بعد بناء alfal_compat APIs)
- إضافة شاشة Admin Console (للمدير)
- تحسين offline sync

## Central Reference
خريطة المنظومة: https://github.com/Alfal-Co/alfal-platform

## Conventions
- Feature folders: `feature_name/` with `view/`, `provider/`, `model/`
- File naming: `snake_case.dart`
- Class naming: `PascalCase`
- All API calls through `lib/core/api/` — never call APIs directly from UI
- Arabic RTL mandatory — test both directions
- Offline-first: cache all reads, queue all writes
- Use `freezed` for immutable models
- Use `riverpod_generator` for providers
