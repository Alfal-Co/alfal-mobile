# مراجعة معمارية — تكامل التطبيق مع البنية التحتية

> التاريخ: 2026-02-27
> من: Claude Code (مسؤول alfal-brain + بنية واتساب الموحدة)
> الغرض: ضمان توافق التطبيق مع البنية التحتية المبنية، وتحديد خطة العمل المستقبلي

---

## 1. تقييم ما تم بناؤه

### التطبيق (alfal-mobile) — ممتاز
| الميزة | التقييم | ملاحظات |
|--------|---------|---------|
| HR Profile | ⭐⭐⭐⭐⭐ | Employee model كامل، انتهاء إقامة، أزرار تواصل |
| WhatsApp QR | ⭐⭐⭐⭐⭐ | base64 decode، polling، pairing code، error handling |
| WhatsApp Service | ⭐⭐⭐⭐⭐ | abstract interface — يدعم تبديل المزود مستقبلاً |
| المبيعات + التحصيل | ⭐⭐⭐⭐⭐ | pagination، فلاتر، تفاصيل |
| المشتريات + AI | ⭐⭐⭐⭐ | workflow متقدم + Raven integration |

### البنية التحتية (alfal-brain) — تعمل
| المكون | الحالة | التفاصيل |
|--------|--------|----------|
| Evolution API v2.3.7 | ✅ شغال | 7 جلسات (alfal-test متصل + 6 بانتظار QR) |
| n8n WA Router | ✅ شغال | webhook → brain.raw_events + brain.messages + ERPNext |
| brain schema | ✅ 25 جدول | messages, groups, group_members, routing_rules, identities... |
| WAHA | ⏸️ متوقف | احتياطي فقط — لا تستخدمه |
| Baileys | ❌ معطّل | أُوقف في كل الـ 6 بوتات |

---

## 2. نقاط التعارض المكتشفة (3 نقاط)

### التعارض #1: نموذج الجلسات (حرج)

**الحالي في التطبيق:**
```
كل موظف → جلسة خاصة (wa_EMP-0001, wa_EMP-0002...)
```

**الواقع في البنية التحتية:**
```
6 أرقام شركة فقط → 6 جلسات (secretary, sales, hr, purchasing, finance, accounting)
```

**لماذا هذا تعارض:** لا يمكن إنشاء 67 جلسة واتساب لأن كل جلسة تحتاج رقم هاتف منفصل. الشركة عندها 6 أرقام فقط.

**الحل الصحيح:**
```
Employee.department → routing_rules → session_name

مثال:
  أحمد (قسم المبيعات) → department = "Sales" → session = "sales"
  سارة (قسم HR)       → department = "HR"    → session = "hr"
```

**التطبيق:** بدل `Employee.whatsapp_session` (custom field per employee)، نستخدم:
```dart
// employee.dart
String get sessionName {
  // أولوية 1: Custom field مباشر (لحالات خاصة)
  if (whatsappSession != null && whatsappSession!.isNotEmpty) {
    return whatsappSession!;
  }
  // أولوية 2: ربط بالقسم عبر routing_rules
  return _departmentToSession(department);
}

static String _departmentToSession(String? dept) {
  switch (dept?.toLowerCase()) {
    case 'sales':
    case 'المبيعات':
      return 'sales';
    case 'hr':
    case 'human resources':
    case 'الموارد البشرية':
      return 'hr';
    case 'purchasing':
    case 'المشتريات':
      return 'purchasing';
    case 'finance':
    case 'المالية':
      return 'finance';
    case 'accounting':
    case 'المحاسبة':
      return 'accounting';
    default:
      return 'secretary'; // الجلسة الافتراضية
  }
}
```

### التعارض #2: المحادثات بدون فلتر

**الحالي:** `conversationsProvider` يجلب كل الرسائل — كل موظف يشوف كل شيء.

**الحل:** فلتر برقم القسم:
```dart
final departmentConversationsProvider =
    FutureProvider.family<List<WaMessage>, String>((ref, deptPhone) async {
  final client = ref.read(erpnextClientProvider);
  final results = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    filters: [
      ['from', 'like', '%$deptPhone%'],  // أو to
    ],
    orderBy: 'creation desc',
    limitPageLength: 100,
  );
  // ... group by phone
});
```

### التعارض #3: الإرسال المباشر لـ Evolution API

**الحالي:** التطبيق يرسل مباشرة لـ Evolution API (API key في التطبيق).

**مقبول حالياً** للتطوير والاختبار. **غير مقبول** للإنتاج لأسباب أمنية.

**الحل المستقبلي:** webhook في n8n يستقبل طلبات الإرسال:
```
POST https://w.alfal.co:5443/webhook/brain-send
Body: { "session": "sales", "to": "966501234567", "text": "..." }
```

---

## 3. المعمارية المستهدفة (الرؤية الكاملة)

### واتساب كنظام تشغيل للشركة

```
┌─────────────────────────────────────────────────────────┐
│                    مصادر الرسائل                         │
│                                                          │
│   عميل يرسل          مندوب يرسل          مورد يرسل     │
│   "أبغى 20 كرتون"    "تم التسليم"        "وصل البضاعة" │
└──────────┬─────────────┬──────────────────┬─────────────┘
           │             │                  │
           ▼             ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│              Evolution API (6 أرقام شركة)                │
│                                                          │
│  كل رسالة → webhook → n8n                               │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│                    n8n (المحرك)                           │
│                                                          │
│  الطبقة 1: التسجيل ✅ (مبني وشغال)                      │
│  ├── حفظ في brain.raw_events                            │
│  ├── حفظ في brain.messages                              │
│  ├── إدارة brain.groups + members                       │
│  └── حفظ في ERPNext WhatsApp Message                    │
│                                                          │
│  الطبقة 2: الفهم ⬜ (المرحلة القادمة)                    │
│  ├── مطابقة الرقم → Customer/Supplier في ERPNext        │
│  ├── AI Parser: "أبغى 20 كرتون" → {item, qty}          │
│  ├── تصنيف: طلب / استفسار / شكوى / تأكيد               │
│  └── تحديث brain.messages.classification                 │
│                                                          │
│  الطبقة 3: الأتمتة ⬜ (بعدها)                            │
│  ├── طلب عميل → Sales Order (مسودة)                     │
│  ├── "تم التسليم" → Delivery Note.status = Delivered    │
│  ├── صورة تحويل → Payment Entry (مسودة)                 │
│  ├── تنبيه: طلب جديد → push notification للمندوب       │
│  └── رد تلقائي: "تم استلام طلبك، رقم الطلب: SO-00123"  │
│                                                          │
│  الطبقة 4: خدمة التطبيق ⬜ (بعدها)                      │
│  ├── /webhook/brain-api  → التطبيق يقرأ المحادثات       │
│  ├── /webhook/brain-send → التطبيق يرسل رسائل           │
│  └── /webhook/brain-status → حالة الجلسات               │
└─────┬────────────┬────────────┬──────────────────────────┘
      │            │            │
      ▼            ▼            ▼
  brain DB     ERPNext      Flutter App
  (تخزين)    (مستندات)    (واجهة المستخدم)
```

---

## 4. خطة العمل المرحلية

### المرحلة الحالية: إصلاح التعارضات (قبل أي عمل جديد)

| # | المهمة | المسؤول | الأثر |
|---|--------|---------|-------|
| A1 | إصلاح session mapping: department → routing_rules | التطبيق | كل موظف يشوف واتساب قسمه |
| A2 | فلترة المحادثات بالقسم | التطبيق | عزل المحادثات حسب الصلاحية |
| A3 | ربط 6 أرقام بـ QR scan | يدوي (محمد) | تشغيل الجلسات فعلياً |

### المرحلة B: واتساب = يفهم (الطبقة 2)

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| B1 | مطابقة رقم → عميل/مورد | n8n + brain | رقم الواتساب → Customer.mobile_no في ERPNext |
| B2 | عرض اسم العميل بدل الرقم | التطبيق | المحادثات تعرض "محمد الأحمدي" بدل "+966501234567" |
| B3 | تصنيف الرسائل (AI أو keywords) | n8n | "أبغى" = طلب، "كم سعر" = استفسار، "تأخر" = شكوى |
| B4 | تنبيه الموظف المناسب | n8n → push | طلب جديد → notification للمندوب |

### المرحلة C: واتساب = ينفّذ (الطبقة 3)

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| C1 | طلب عميل → Sales Order مسودة | n8n → ERPNext API | AI يفهم "20 كرتون دجاج" → SO |
| C2 | "تم التسليم" → Delivery Note | n8n → ERPNext API | المندوب يأكد بكلمة واحدة |
| C3 | صورة تحويل → Payment Entry | n8n → ERPNext API | OCR أو يدوي مع ربط بالفاتورة |
| C4 | رد تلقائي للعميل | n8n → Evolution API | "تم استلام طلبك رقم SO-00123" |

### المرحلة D: التطبيق يمر عبر n8n (الطبقة 4)

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| D1 | n8n brain-api webhook | n8n | التطبيق يقرأ من brain بدل ERPNext مباشرة |
| D2 | n8n brain-send webhook | n8n | التطبيق يرسل عبر n8n (API key server-side) |
| D3 | إزالة Evolution API key من التطبيق | التطبيق | الأمان: المفتاح في السيرفر فقط |
| D4 | Meta Cloud API provider | التطبيق + n8n | عند اعتماد Meta — نبدّل المزود بدون تغيير التطبيق |

---

## 5. الربط بين المشاريع

```
alfal-mobile (Flutter)
    │
    │ يقرأ: ERPNext API (حالياً) → n8n brain-api (مستقبلاً)
    │ يرسل: Evolution API (حالياً) → n8n brain-send (مستقبلاً)
    │
alfal-brain (PostgreSQL + n8n)
    │
    │ يستقبل: Evolution API webhooks
    │ يخزن: brain.messages, brain.groups, brain.raw_events
    │ يخدم: التطبيق + البوتات + التقارير
    │
alfal-bots (6 بوتات OpenClaw)
    │
    │ Baileys: ❌ معطّل
    │ المستقبل: يستقبل من n8n → يرد عبر Evolution API
    │
ERPNext (w.alfal.co)
    │
    │ المصدر: عملاء، فواتير، موظفين، مخزون
    │ الهدف: Sales Orders, Delivery Notes, Payment Entries (من واتساب)
```

---

## 6. القواعد الذهبية

### للتطبيق (alfal-mobile):
1. **لا تبني session per employee** — استخدم department → routing_rules
2. **الإرسال المباشر مقبول للتطوير** — لكن صمم الكود جاهز للتحويل لـ n8n
3. **WhatsAppService interface ممتاز** — حافظ عليه، سنضيف n8nProxyProvider لاحقاً
4. **فلتر المحادثات بالقسم** — كل موظف يشوف قسمه فقط

### للبنية التحتية (alfal-brain):
1. **n8n هو المحرك** — كل أتمتة تمر عبره
2. **brain.messages هو مصدر الحقيقة** — التطبيق يقرأ منه (حالياً عبر ERPNext، مستقبلاً مباشرة)
3. **Evolution API = المزود الحالي** — Meta Cloud API = المستقبلي
4. **WAHA = متوقف** — لا تفعّله إلا في الطوارئ

### للجميع:
1. **لا تكرر البيانات** — مصدر واحد لكل معلومة
2. **لا تتصل مباشرة** — كل شيء عبر API/webhook محدد
3. **خطة قبل تنفيذ** — أي تغيير كبير يحتاج مراجعة في هذا الملف أولاً

---

## 7. مزودي واتساب — القرار النهائي

| المزود | الدور | متى |
|--------|-------|-----|
| **Evolution API** | أساسي — QR code | الآن وحتى اعتماد Meta |
| **Meta Cloud API** | رسمي — API بدون QR | عند اعتماد التطبيق من Meta |
| **WAHA** | احتياطي طوارئ | فقط لو فشل Evolution كلياً |
| **Baileys مباشر** | ملغي | لا يُستخدم أبداً |

**الانتقال من Evolution إلى Meta:** التطبيق جاهز بفضل `WhatsAppService` interface — نضيف `MetaCloudProvider` implements `WhatsAppService` ونبدّل.

---

> هذا الملف يُحدّث عند كل قرار معماري كبير.
> آخر تحديث: 2026-02-27
