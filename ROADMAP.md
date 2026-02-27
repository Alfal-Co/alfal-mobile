# خارطة الطريق - تطبيق الفال

> أفضل تطبيق مبيعات ميداني للدواجن في الشرق الأوسط
> آخر تحديث: 2026-02-27

---

## الرؤية

```
ERPNext (Backend قوي)
     │
     │ REST API
     │
Flutter App (واجهة بسيطة + Offline)
     │
     ├── المبيعات (إنشاء فاتورة في 5 ثواني)
     ├── العملاء (مدمج في المبيعات)
     ├── التحصيل (نقد / تحويل / شبكة)
     ├── المشتريات (طلبات + workflow)
     ├── الموظفين (ملف شخصي + إقامة)
     ├── واتساب (محادثات + QR + إرسال)
     ├── الزيارات (GPS + check-in/out)
     └── لوحة تحكم (مبيعات + تحصيل + أداء)
```

### القاعدة الذهبية

```
نصف النظام في ERPNext (محاسبة، مخزون، فواتير، عملاء)
نصف النظام في التطبيق (واجهة ميدانية سريعة + واتساب + GPS)
```

---

## حالة المراحل

| # | المرحلة | الحالة |
|---|---------|--------|
| 1 | الأساس (هيكل + تسجيل دخول + داشبورد) | ✅ مكتملة |
| 2 | العمليات (عملاء + فواتير + تحصيل + مشتريات) | ✅ مكتملة |
| 3 | الموظفين + واتساب (HR + Evolution API) | ✅ مكتملة |
| 4 | الميزات الميدانية (GPS + Offline + كاميرا) | ⬜ التالية |
| 5 | الذكاء والإشعارات (Claude AI + Push) | ⬜ مخطط |
| 6 | واتساب متقدم (ربط عملاء + صلاحيات) | ⬜ مخطط |
| 7 | النشر والتحسين (Store + أداء + اختبارات) | ⬜ مخطط |

---

## المرحلة 1: الأساس ✅

- [x] هيكل المشروع (Flutter + Riverpod + GoRouter + Dio)
- [x] ثيم الفال (Material3 + أخضر + خط Tajawal + RTL)
- [x] تسجيل الدخول (username/password + API token)
- [x] حفظ الجلسة (SharedPreferences)
- [x] داشبورد (مبيعات يومية + فواتير + عملاء + موردين + مشتريات)
- [x] ERPNext Client (Dio + interceptors + CRUD + getCount + call)

---

## المرحلة 2: العمليات الأساسية ✅

- [x] قائمة العملاء (بحث + pagination + رصيد)
- [x] تفاصيل العميل
- [x] فواتير المبيعات (فلاتر: الكل/غير مدفوعة/مدفوعة/مسودة/ملغية)
- [x] تفاصيل الفاتورة
- [x] التحصيل (قائمة + مجموع يومي + فلاتر)
- [x] تفاصيل الدفعة
- [x] المشتريات (طلبات شراء + workflow stepper + 8 حالات)
- [x] إنشاء طلب شراء
- [x] واتساب pull request

---

## المرحلة 3: الموظفين + واتساب ✅

### HR - الملف الشخصي
- [x] Employee model (اسم، مسمى، قسم، فرع، إقامة، تواصل)
- [x] myEmployeeProvider (user_id → Employee → getDoc)
- [x] شاشة الملف الشخصي (avatar + بيانات + تواصل)
- [x] تنبيه انتهاء الإقامة (30 يوم / منتهية)
- [x] أزرار اتصال + واتساب (url_launcher)
- [x] tab "الموظفين" في الشريط السفلي (بدل العملاء)
- [x] العملاء يوصلهم من أيقونة في شاشة المبيعات

### واتساب - Evolution API
- [x] WhatsApp Service (abstract + Evolution implementation)
- [x] فحص اتصال الجلسة (connectionState)
- [x] QR code screen (base64 decode + pairing code + polling كل 5 ثواني)
- [x] إرسال رسائل نصية
- [x] شاشة المحادثات (مجمعة بالرقم)
- [x] شاشة المحادثة (bubbles + إرسال)
- [x] كارت واتساب في الملف الشخصي

---

## المرحلة 4: الميزات الميدانية ⬜ (التالية)

### 4.1 — إنشاء فاتورة سريعة
> المندوب ينشئ فاتورة في 5 ثواني

- [ ] شاشة إنشاء فاتورة مبيعات
- [ ] اختيار عميل (بحث سريع)
- [ ] اختيار منتجات (بحث + باركود)
- [ ] حساب تلقائي (كمية × سعر + VAT 15%)
- [ ] حفظ وإرسال إلى ERPNext
- [ ] مشاركة الفاتورة (PDF / واتساب)

### 4.2 — تتبع الزيارات (GPS)
> المدير يعرف وين المندوب وكم عميل زار

- [ ] إضافة `geolocator` + `google_maps_flutter` في pubspec
- [ ] تسجيل بداية/نهاية اليوم
- [ ] Check-in / Check-out عند العميل (مع إحداثيات)
- [ ] خريطة مسار المندوب اليومي
- [ ] تقرير زيارات للمدير

### 4.3 — Offline First
> المندوب يشتغل حتى بدون إنترنت

- [ ] تخزين العملاء + المنتجات + الأسعار في Hive
- [ ] إنشاء فواتير offline (حفظ محلي)
- [ ] قائمة انتظار المزامنة (sync queue)
- [ ] مزامنة تلقائية عند عودة الاتصال
- [ ] مؤشر حالة الاتصال واضح
- [ ] حل تعارضات البيانات

### 4.4 — الكاميرا والملفات
- [ ] إضافة `mobile_scanner` في pubspec
- [ ] مسح باركود المنتجات
- [ ] تصوير إيصالات الدفع
- [ ] رفع الصور إلى ERPNext

### 4.5 — التحصيل الذكي
> المندوب يسجل تحصيل فوري من العميل

- [ ] إنشاء Payment Entry من التطبيق
- [ ] أنواع الدفع (نقد / تحويل / شبكة)
- [ ] تصوير إيصال التحويل
- [ ] ربط الدفعة بالفواتير المستحقة
- [ ] تقرير تحصيل يومي

---

## المرحلة 5: الذكاء والإشعارات ⬜

### 5.1 — Claude AI Assistant
- [ ] ربط Claude API مع سياق ERPNext
- [ ] "كم رصيد العميل محمد؟"
- [ ] "وش أكثر منتج مبيعاً هالشهر؟"
- [ ] "من أفضل مندوب اليوم؟"
- [ ] ربط مع n8n للاستعلامات المعقدة

### 5.2 — إشعارات Push
- [ ] إعداد Firebase Cloud Messaging
- [ ] إشعار فاتورة جديدة
- [ ] إشعار دفعة مستلمة
- [ ] تذكير تحصيل
- [ ] إشعارات الموافقات (workflow)

---

## المرحلة 6: واتساب متقدم ⬜

### استراتيجية الواتساب (4 مستويات)

```
المستوى 1 ✅  كل موظف يرى واتسابه (QR + session)
المستوى 2 ⬜  ربط العميل برقم واتساب (اسم بدل رقم)
المستوى 3 ⬜  المندوب يرى عملائه فقط (حسب Territory)
المستوى 4 ⬜  WhatsApp Business API (بدون QR)
```

### المستوى 2 — ربط العميل بالواتساب
- [ ] مطابقة رقم واتساب مع `mobile_no` في Customer
- [ ] عرض اسم العميل بدل الرقم في المحادثات
- [ ] فتح محادثة العميل من تفاصيل العميل

### المستوى 3 — صلاحيات المندوب
- [ ] المندوب يرى محادثات عملائه فقط (حسب Territory/Sales Partner)
- [ ] المدير يرى كل المحادثات
- [ ] allEmployeesProvider (قائمة كل الموظفين للمدير)

### المستوى 4 — WhatsApp Business API
- [ ] الانتقال من QR إلى Business API
- [ ] Evolution multi-device API
- [ ] إرسال فواتير PDF عبر واتساب
- [ ] قوالب رسائل (تأكيد طلب / تذكير دفع)

---

## المرحلة 7: النشر والتحسين ⬜

- [ ] Dark mode
- [ ] Shimmer loading effects (`shimmer`)
- [ ] Cached images (`cached_network_image`)
- [ ] Responsive UI (`flutter_screenutil`)
- [ ] Animations (`flutter_animate`)
- [ ] اختبارات وحدة وتكامل
- [ ] إعداد للنشر على App Store / Play Store

---

## البنية التقنية

### المكتبات الحالية
```yaml
# مثبت ✅
flutter_riverpod: ^2.5.0     # State Management
go_router: ^14.0.0           # Navigation
dio: ^5.4.0                  # HTTP Client
hive_flutter: ^1.1.0         # Local Storage
shared_preferences: ^2.2.0   # Session
fl_chart: ^0.68.0            # Charts
intl: ^0.20.2                # i18n
connectivity_plus: ^6.0.0    # Network Status
path_provider: ^2.1.0        # File Paths
url_launcher: ^6.2.0         # External Links
```

### مكتبات المرحلة 4 (تُضاف لاحقاً)
```yaml
# GPS + خرائط
geolocator: ^12.0.0
google_maps_flutter: ^2.6.0

# كاميرا + باركود
mobile_scanner: ^5.0.0

# صور مخزنة
cached_network_image: ^3.3.0
```

### مكتبات المرحلة 5+ (تُضاف لاحقاً)
```yaml
# إشعارات
firebase_messaging: ^15.0.0
flutter_local_notifications: ^17.0.0

# تحسينات UI
shimmer: ^3.0.0
flutter_animate: ^4.0.0
flutter_screenutil: ^5.9.0
```

---

## ERPNext API Endpoints

### المصادقة
```
POST /api/method/login
GET  /api/method/frappe.auth.get_logged_user
GET  /api/resource/User/{email}
```

### العملاء
```
GET  /api/resource/Customer?filters=...&fields=...
GET  /api/resource/Customer/{name}
POST /api/resource/Customer
GET  /api/method/erpnext.accounts.utils.get_balance_on
```

### فواتير المبيعات
```
GET  /api/resource/Sales Invoice?filters=...
POST /api/resource/Sales Invoice
PUT  /api/resource/Sales Invoice/{name}
POST /api/method/frappe.client.submit
```

### المنتجات
```
GET  /api/resource/Item?filters=...&fields=...
GET  /api/resource/Item Price?filters=...
GET  /api/resource/Bin?filters=...
```

### المدفوعات
```
POST /api/resource/Payment Entry
GET  /api/resource/Payment Entry?filters=...
```

### الموظفين
```
GET  /api/resource/Employee?filters=[["user_id","=","..."]]
GET  /api/resource/Employee/{name}
```

### واتساب (Evolution API)
```
GET  /instance/connectionState/{session}
GET  /instance/connect/{session}
POST /message/sendText/{session}
```

### واتساب (ERPNext)
```
GET  /api/resource/WhatsApp Message?filters=...
```

### عام
```
POST /api/method/frappe.client.get_count
POST /api/method/upload_file
```

---

## هيكل المشروع

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # Material3 + RTL
│   └── routes.dart           # GoRouter + bottom nav
├── core/
│   ├── api/
│   │   ├── erpnext_client.dart    # REST API client
│   │   └── whatsapp_service.dart  # Evolution API
│   ├── auth/
│   │   └── auth_provider.dart     # Login + session
│   ├── config/
│   │   └── app_config.dart        # URLs + keys
│   ├── theme/
│   │   └── app_theme.dart         # Alfal green theme
│   └── offline/                   # ⬜ Sync engine (Hive)
├── features/
│   ├── auth/view/                 # ✅ Login
│   ├── dashboard/                 # ✅ Home + stats
│   ├── customers/                 # ✅ List + detail
│   ├── sales/                     # ✅ Invoices + filters
│   ├── payments/                  # ✅ Collection
│   ├── procurement/               # ✅ Material requests
│   ├── hr/                        # ✅ My profile
│   ├── whatsapp/                  # ✅ QR + chat
│   ├── ai_assistant/              # ✅ Claude chat (basic)
│   ├── inventory/                 # ⬜ Stock + barcode
│   └── visits/                    # ⬜ GPS tracking
└── shared/
    ├── models/
    ├── widgets/
    └── utils/
```

---

## الأولويات

| الميزة | الأولوية | المرحلة | الحالة |
|--------|----------|---------|--------|
| تسجيل الدخول | حرج | 1 | ✅ |
| داشبورد | مهم | 1 | ✅ |
| قائمة العملاء | حرج | 2 | ✅ |
| فواتير المبيعات | حرج | 2 | ✅ |
| التحصيل | حرج | 2 | ✅ |
| المشتريات | مهم | 2 | ✅ |
| الموظفين (HR) | مهم | 3 | ✅ |
| واتساب | مهم | 3 | ✅ |
| إنشاء فاتورة سريعة | حرج | 4 | ⬜ |
| Offline mode | مهم | 4 | ⬜ |
| GPS | مهم | 4 | ⬜ |
| تحصيل ذكي | مهم | 4 | ⬜ |
| باركود | مفيد | 4 | ⬜ |
| Claude AI | مفيد | 5 | ⬜ |
| إشعارات Push | مفيد | 5 | ⬜ |
| واتساب متقدم | مفيد | 6 | ⬜ |
| نشر Store | لاحقاً | 7 | ⬜ |

---

## 5 ميزات تصنع الفارق

```
1. إنشاء فاتورة في 5 ثواني (عميل → منتجات → حفظ)
2. واتساب داخل التطبيق (فاتورة + موقع + صورة)
3. GPS للزيارات (check-in/out + مسار يومي)
4. تحصيل ذكي (تصوير إيصال + ربط بفاتورة)
5. لوحة تحكم للمدير (مبيعات + تحصيل + أفضل مندوب)
```
