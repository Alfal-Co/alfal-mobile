# تطبيق الفال - Alfal Mobile

> تطبيق موبايل مبني بـ Flutter يتكامل مع ERPNext v16 لشركة الفال قوت للتجارة

## الرؤية

تطبيق موبايل شامل للمناديب والمدراء والمستودعات، يعمل offline ويتكامل مع ERPNext عبر Frappe SDK، مع ذكاء اصطناعي مدمج (Claude AI).

## المميزات المخططة

### المرحلة 1 - الأساس (MVP)
- [ ] تسجيل دخول عبر ERPNext API
- [ ] داشبورد المدير (مبيعات يومية، تحصيلات، أداء المناديب)
- [ ] قائمة العملاء مع البحث والفلترة
- [ ] عرض أرصدة العملاء

### المرحلة 2 - تطبيق المندوب
- [ ] إنشاء فواتير مبيعات
- [ ] تحصيل مدفوعات
- [ ] تتبع GPS للزيارات
- [ ] كاميرا لتصوير الإيصالات
- [ ] وضع Offline مع مزامنة تلقائية

### المرحلة 3 - الذكاء الاصطناعي
- [ ] دمج Claude AI (استعلامات صوتية/نصية)
- [ ] "كم رصيد العميل فلان؟"
- [ ] تقارير ذكية وتوصيات
- [ ] ربط مع بوتات WhatsApp الموجودة

### المرحلة 4 - متقدم
- [ ] POS كامل
- [ ] إدارة المستودعات (جرد، تحويلات)
- [ ] إشعارات Push
- [ ] تقارير وتحليلات متقدمة

## التقنيات

| التقنية | الاستخدام |
|---------|-----------|
| Flutter 3.x | إطار التطبيق (iOS + Android) |
| Dart | لغة البرمجة |
| Frappe Dart SDK | الاتصال بـ ERPNext API |
| Hive / SQLite | تخزين محلي (Offline) |
| Riverpod | إدارة الحالة |
| GoRouter | التنقل |
| Claude API | الذكاء الاصطناعي |
| Firebase | إشعارات Push |

## البيئة

| الخدمة | الرابط |
|--------|--------|
| ERPNext v16 | `https://w.alfal.co` |
| n8n | `https://w.alfal.co:5443` |

## البدء السريع

```bash
# متطلبات
flutter --version  # Flutter 3.x+

# تشغيل
git clone https://github.com/Alfal-Co/alfal-mobile.git
cd alfal-mobile
flutter pub get
flutter run
```

## هيكل المشروع

```
alfal-mobile/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   ├── core/
│   │   ├── api/              # Frappe/ERPNext API client
│   │   ├── auth/             # Authentication
│   │   ├── config/           # App configuration
│   │   ├── offline/          # Offline sync engine
│   │   └── theme/            # App theme
│   ├── features/
│   │   ├── dashboard/        # Manager dashboard
│   │   ├── customers/        # Customer management
│   │   ├── sales/            # Sales invoices
│   │   ├── payments/         # Payment collection
│   │   ├── inventory/        # Stock & warehouse
│   │   ├── hr/               # HR self-service
│   │   ├── visits/           # GPS visit tracking
│   │   └── ai_assistant/     # Claude AI chat
│   └── shared/
│       ├── widgets/          # Reusable widgets
│       └── models/           # Shared data models
├── assets/
│   ├── images/
│   └── fonts/
├── test/
├── android/
├── ios/
├── pubspec.yaml
└── ROADMAP.md
```

## الترخيص

MIT License - Alfal-Co
