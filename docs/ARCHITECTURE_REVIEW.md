# مراجعة معمارية — تكامل التطبيق مع البنية التحتية

> التاريخ: 2026-02-27
> من: Claude Code (مسؤول alfal-brain + بنية واتساب الموحدة)
> الغرض: ضمان توافق التطبيق مع البنية التحتية المبنية، وتحديد خطة العمل المستقبلي
> آخر تحديث: 2026-02-27 — تصحيح نموذج الجلسات (الرقم للموظف وليس للقسم/البوت)

---

## 1. الحقيقة الجوهرية: الرقم للموظف وليس للبوت

**بعد تعطيل Baileys** في كل البوتات الستة، أرقام الشركة **رجعت لأصحابها** (المدراء/الموظفين):

```
❌ خطأ سابق:  +966555339356 = "بوت المالية"         ← البوت يملك الرقم
❌ خطأ ثاني:   +966555339356 = "جلسة قسم المالية"    ← القسم يملك الرقم
✅ صحيح:       +966555339356 = مدير المالية (إنسان)  ← الموظف يملك رقمه
               بوت المالية = مستخدم ERPNext (finance-bot@alfal.co) يساعد المدير
```

### القاعدة:
| الكيان | ملكيته | هويته في النظام |
|--------|--------|----------------|
| **رقم الواتساب** | الموظف (cell_phone في ERPNext) | session في Evolution API باسم الرقم |
| **البوت** | النظام | مستخدم ERPNext (finance-bot@alfal.co) — يسجل إجراءاته باسمه |
| **الرسائل** | تمر عبر رقم الموظف | n8n يوجّه للبوت المناسب ويخزن في brain |

---

## 2. نموذج الجلسات الصحيح

### كيف يعمل:
```
الموظف يدخل التطبيق
  → التطبيق يسحب بياناته من ERPNext (بما فيها cell_phone)
  → لو cell_phone موجود:
      → session_name = الرقم بدون + (مثل: 966555339356)
      → فحص حالة الاتصال: GET /instance/connectionState/{session_name}
      → لو "open" → متصل ✅ (يعرض المحادثات)
      → لو لا → إنشاء session: POST /instance/create
      → جلب QR: GET /instance/connect/{session_name}
      → الموظف يمسح QR → متصل
  → لو cell_phone فاضي:
      → "لا يوجد رقم شركة مرتبط بحسابك"
```

### لا تحفظ أرقام في الكود:
```dart
// ❌ خطأ — لا تحفظ أرقام
const sessionPhones = {
  'sales': '+966550442804',
  'hr': '+966565564518',
};

// ❌ خطأ — لا تربط قسم بجلسة
String _departmentToSession(String dept) => ...

// ✅ صحيح — الرقم يجي من ERPNext فقط
String get sessionName {
  if (cellPhone == null || cellPhone!.isEmpty) return '';
  // ينظّف الرقم: +966555339356 → 966555339356
  return cellPhone!.replaceAll(RegExp(r'[^0-9]'), '');
}
```

### من يحتاج جلسة واتساب؟
**فقط الموظفين اللي عندهم `cell_phone`** (رقم شركة) في ERPNext. مو كل الـ 67 موظف — بس المدراء واللي عندهم أرقام شركة.

---

## 3. البوت كمساعد (وليس مالك الرقم)

### الفصل الواضح:
```
┌─────────────────────────────────────────────────────────┐
│  مدير المالية (إنسان)                                    │
│  رقمه: +966555339356                                     │
│  واتسابه: مربوط عبر QR في التطبيق                       │
│                                                          │
│  عميل يرسل رسالة لرقمه                                   │
│         │                                                │
│         ▼                                                │
│  Evolution API يستقبل ← webhook → n8n                   │
│         │                                                │
│         ├── يخزن في brain.messages ✅                    │
│         ├── يظهر في التطبيق (المدير يشوفها) ✅           │
│         └── يوجّه للبوت المالي (finance-bot) ✅          │
│                    │                                     │
│                    ▼                                     │
│  البوت يحلل الرسالة:                                     │
│    - "كم رصيد فاتورة 123" → يجيب من ERPNext             │
│    - "سوّي سند قبض" → يسوي Payment Entry باسم البوت     │
│    - يرد عبر Evolution API باستخدام رقم المدير          │
│                                                          │
│  كل إجراء في ERPNext يُسجل بمستخدم البوت:               │
│    Created by: finance-bot@alfal.co                      │
└─────────────────────────────────────────────────────────┘
```

### هوية البوت في ERPNext:
| البوت | المستخدم في ERPNext | الرقم المرتبط (رقم المدير) |
|-------|---------------------|---------------------------|
| سكرتير المدير | botmhd@alfal.co | يُحدد من ERPNext Employee |
| مساعد المبيعات | ceo-bot@alfal.co | يُحدد من ERPNext Employee |
| الموارد البشرية | hr-bot@alfal.co | يُحدد من ERPNext Employee |
| المشتريات | purchase-bot@alfal.co | يُحدد من ERPNext Employee |
| المالية | finance-bot@alfal.co | يُحدد من ERPNext Employee |
| المحاسبة | accounting-bot@alfal.co | يُحدد من ERPNext Employee |

---

## 4. التعديلات المطلوبة على التطبيق

### 4.1 Employee Model (`lib/features/hr/model/employee.dart`)

**الحالي (خطأ):**
```dart
String get sessionName =>
    whatsappSession ?? 'wa_${name.replaceAll(' ', '_')}';
```

**المطلوب:**
```dart
/// اسم الجلسة = رقم الشركة بدون رموز
/// لو ما فيه رقم شركة = ما يقدر يربط واتساب
String get sessionName {
  if (cellPhone == null || cellPhone!.isEmpty) return '';
  return cellPhone!.replaceAll(RegExp(r'[^0-9]'), '');
}

/// هل يقدر يربط واتساب؟
bool get canConnectWhatsApp =>
    cellPhone != null && cellPhone!.isNotEmpty;
```

- **احذف** `whatsappSession` field و `_departmentToSession()` والأرقام المحفوظة
- **لا تحفظ أرقام** في الكود — كلها تجي من ERPNext

### 4.2 WhatsApp Service (`lib/core/api/whatsapp_service.dart`)

**أضف** method لإنشاء session جديد:
```dart
abstract class WhatsAppService {
  Future<QrResult> getQrCode(String session);
  Future<String> checkConnection(String session);
  Future<void> sendText(String session, String to, String text);
  Future<void> createSession(String sessionName);  // ← جديد
}
```

**التنفيذ في Evolution:**
```dart
@override
Future<void> createSession(String sessionName) async {
  await _dio.post('/instance/create', data: {
    'instanceName': sessionName,
    'integration': 'WHATSAPP-BAILEYS',
    'qrcode': true,
  });
}
```

### 4.3 WhatsApp Provider (`lib/features/whatsapp/provider/whatsapp_provider.dart`)

**conversationsProvider:**
```dart
final conversationsProvider = FutureProvider<List<WaMessage>>((ref) async {
  final client = ref.read(erpnextClientProvider);
  final employee = await ref.watch(myEmployeeProvider.future);

  if (employee == null || !employee.canConnectWhatsApp) return [];

  final phone = employee.cellPhone!;

  // فلتر برقم الموظف نفسه (مو رقم القسم)
  final incoming = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    filters: [['to', 'like', '%$phone%']],
    orderBy: 'creation desc',
    limitPageLength: 200,
  );

  final outgoing = await client.getList(
    'WhatsApp Message',
    fields: ['name', '`from`', 'to', 'message', 'type', 'creation'],
    filters: [['from', 'like', '%$phone%']],
    orderBy: 'creation desc',
    limitPageLength: 200,
  );

  // دمج وترتيب وتجميع بالرقم...
});
```

### 4.4 Profile Screen (`lib/features/hr/view/my_profile_screen.dart`)

**زر واتساب يظهر فقط لو فيه رقم شركة:**
```dart
// في _WhatsAppCard:
if (!employee.canConnectWhatsApp) {
  return Text('لا يوجد رقم شركة مرتبط');
}
// ... باقي الكود (QR + محادثات)
```

### 4.5 QR Screen — التدفق الجديد

```dart
// في whatsapp_qr_screen.dart — عند الضغط على "ربط واتساب":
// 1. فحص لو الجلسة موجودة
final state = await service.checkConnection(sessionName);
if (state == 'error') {
  // 2. إنشاء جلسة جديدة أول مرة
  await service.createSession(sessionName);
}
// 3. جلب QR code
final qr = await service.getQrCode(sessionName);
```

---

## 5. Evolution API — إنشاء Session ديناميكي

### Endpoint:
```http
POST /instance/create
Content-Type: application/json
Header: apikey: {EVOLUTION_API_KEY}

{
  "instanceName": "966555339356",
  "integration": "WHATSAPP-BAILEYS",
  "qrcode": true
}
```

### بعدها:
```http
GET /instance/connect/966555339356    → QR code (base64)
GET /instance/connectionState/966555339356 → حالة الاتصال
```

---

## 6. المعمارية المستهدفة (محدّثة)

```
┌─────────────────────────────────────────────────────────┐
│  التطبيق (Flutter)                                       │
│                                                          │
│  موظف يدخل → يسحب cell_phone من ERPNext                │
│  → يسوي session بالرقم → QR → يمسح → متصل              │
│  → يشوف محادثات رقمه → يرسل/يستقبل                     │
└──────────────────────┬───────────────────────────────────┘
                       │ Evolution API (حالياً)
                       │ n8n proxy (مستقبلاً)
                       ▼
┌──────────────────────────────────────────────────────────┐
│  Evolution API (w.alfal.co:8085)                         │
│                                                          │
│  Sessions ديناميكية (per phone number):                  │
│  966555339356 → مدير المالية                             │
│  966550442804 → مدير المبيعات                            │
│  ... أي رقم يُربط من التطبيق                            │
│                                                          │
│  كل رسالة → webhook → n8n                               │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│  n8n (المحرك)                                            │
│                                                          │
│  1. يخزن في brain.messages ✅                           │
│  2. يحدد هوية المرسل (brain.identities)                 │
│  3. يوجّه للبوت المناسب حسب routing_rules               │
│  4. البوت يحلل ويرد (باستخدام مستخدمه في ERPNext)       │
└─────┬──────────────┬──────────────┬─────────────────────┘
      │              │              │
      ▼              ▼              ▼
  brain DB       ERPNext        6 بوتات
  (تخزين)      (مستندات)      (مساعدين AI)
               البوت يسجل      كل بوت = مستخدم ERPNext
               باسمه هنا       يساعد المدير صاحب الرقم
```

---

## 7. خطة العمل المرحلية

### المرحلة الحالية: تصحيح نموذج الجلسات

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| A1 | تعديل `sessionName` → يُشتق من `cellPhone` | التطبيق | لا أرقام محفوظة في الكود |
| A2 | إضافة `createSession()` في WhatsApp service | التطبيق | لإنشاء session ديناميكي |
| A3 | فلترة المحادثات برقم الموظف | التطبيق | كل موظف يشوف رقمه فقط |
| A4 | زر واتساب يظهر فقط لمن عنده `cell_phone` | التطبيق | `canConnectWhatsApp` getter |
| A5 | تمرير `sessionName` عند فتح الشات | التطبيق | لتفعيل زر الإرسال |

### المرحلة B: واتساب = يفهم (الطبقة 2)

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| B1 | مطابقة رقم → عميل/مورد | n8n + brain | رقم الواتساب → Customer.mobile_no في ERPNext |
| B2 | عرض اسم العميل بدل الرقم | التطبيق | المحادثات تعرض "محمد الأحمدي" بدل "+966501234567" |
| B3 | تصنيف الرسائل (AI أو keywords) | n8n | "أبغى" = طلب، "كم سعر" = استفسار |
| B4 | تنبيه الموظف المناسب | n8n → push | طلب جديد → notification |

### المرحلة C: واتساب = ينفّذ (الطبقة 3)

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| C1 | طلب عميل → Sales Order مسودة | n8n → ERPNext API | باستخدام مستخدم البوت |
| C2 | "تم التسليم" → Delivery Note | n8n → ERPNext API | المندوب يأكد بكلمة واحدة |
| C3 | صورة تحويل → Payment Entry | n8n → ERPNext API | OCR أو يدوي |
| C4 | رد تلقائي للعميل | n8n → Evolution API | "تم استلام طلبك رقم SO-00123" |

### المرحلة D: التطبيق يمر عبر n8n (الطبقة 4)

| # | المهمة | المسؤول | التفاصيل |
|---|--------|---------|----------|
| D1 | n8n brain-api webhook | n8n | التطبيق يقرأ من brain |
| D2 | n8n brain-send webhook | n8n | التطبيق يرسل عبر n8n |
| D3 | إزالة Evolution API key من التطبيق | التطبيق | الأمان |
| D4 | Meta Cloud API provider | التطبيق + n8n | عند اعتماد Meta |

---

## 8. القواعد الذهبية (محدّثة)

### للتطبيق (alfal-mobile):
1. **الرقم للموظف وليس للبوت/القسم** — session = cellPhone من ERPNext
2. **لا تحفظ أرقام في الكود** — كل شيء يُسحب من ERPNext API
3. **WhatsAppService interface ممتاز** — أضف `createSession()` وحافظ على الباقي
4. **فلتر المحادثات برقم الموظف** — كل موظف يشوف رقمه فقط
5. **زر واتساب مشروط** — يظهر فقط لو `canConnectWhatsApp`

### للبوتات:
1. **البوت مساعد وليس مالك** — الرقم للإنسان، البوت يساعده
2. **كل إجراء يُسجل بمستخدم البوت** — finance-bot@alfal.co ينشئ Payment Entry
3. **البوت يستقبل من n8n** — ما يتصل بواتساب مباشرة

### للبنية التحتية (alfal-brain):
1. **n8n هو المحرك** — كل أتمتة تمر عبره
2. **brain.messages مصدر الحقيقة** — التطبيق يقرأ منه
3. **Evolution API = المزود الحالي** — Meta Cloud API = المستقبلي
4. **WAHA = متوقف** — لا تفعّله إلا في الطوارئ

---

## 9. مزودي واتساب — القرار النهائي

| المزود | الدور | متى |
|--------|-------|-----|
| **Evolution API** | أساسي — QR code + sessions ديناميكية | الآن وحتى اعتماد Meta |
| **Meta Cloud API** | رسمي — API بدون QR | عند اعتماد التطبيق من Meta |
| **WAHA** | احتياطي طوارئ | فقط لو فشل Evolution كلياً |
| **Baileys مباشر** | ملغي | لا يُستخدم أبداً |

---

## 10. خطة إعادة بناء البوتات (تحت المراجعة)

> **الحالة: تحت المراجعة** — لا تُنفّذ إلا بعد موافقة صريحة من محمد

### الوضع الحالي للبوتات:
بعد تعطيل Baileys، البوتات صارت تعتمد على:
- **n8n** لاستقبال الرسائل وتوجيهها
- **Evolution API** كبوابة واتساب
- **ERPNext** لتنفيذ الإجراءات
- **Raven** كواجهة داخلية (مساعد الفال — gpt-4o-mini)

### هوية البوت الصحيحة في ERPNext:

#### 3 طبقات:

**الطبقة 1 — هوية (ERPNext Users):**
الـ 6 مستخدمين بوت يبقون في ERPNext كهوية وأثر تتبع (audit trail):

| المستخدم | الدور | الغرض |
|----------|-------|-------|
| `finance-bot@alfal.co` | Accounts Manager | n8n يسوي Payment Entry → يُسجل باسم هذا المستخدم |
| `hr-bot@alfal.co` | HR Manager | n8n يسوي Leave Application → يُسجل باسم هذا المستخدم |
| `purchase-bot@alfal.co` | Purchase Manager | n8n يسوي Purchase Order → يُسجل باسم هذا المستخدم |
| `ceo-bot@alfal.co` | Sales User | n8n يسوي Sales Order → يُسجل باسم هذا المستخدم |
| `botmhd@alfal.co` | System Manager (محدود) | مهام إدارية عامة |
| `accounting-bot@alfal.co` | Accounts User | تقارير + compliance |

كل إجراء يُسجل باسم البوت المختص — ما يضيع المسؤولية.

**الطبقة 2 — الدماغ (n8n):**
n8n يتولى كل ما كانت البوتات تسويه:

| القدرة | التنفيذ في n8n |
|--------|---------------|
| استقبال رسائل واتساب | Webhook من Evolution API |
| تحليل ذكي | OpenAI node — يفهم "أبغى 20 كرتون" = طلب |
| اتخاذ قرارات | IF/Switch nodes + AI Classification |
| إنشاء مستندات ERPNext | ERPNext API node باستخدام API Key البوت المناسب |
| متابعة دورية | Cron triggers — فواتير متأخرة، إقامات منتهية |
| تنبيهات | Push notification + Raven + WhatsApp reply |
| تقارير | جمع بيانات + ملخص يومي/أسبوعي |

**مثال — workflow واتساب ذكي:**
```
رسالة واتساب واردة
  ↓
n8n: تحليل AI (OpenAI node)
  ├── "أبغى 20 كرتون دجاج"
  │     → تصنيف: طلب
  │     → Sales Order (مسودة) بهوية ceo-bot
  │     → رد واتساب: "تم إنشاء طلب SO-00789"
  │
  ├── "كم رصيدي؟"
  │     → تصنيف: استفسار
  │     → جلب Outstanding بهوية finance-bot
  │     → رد واتساب: "رصيدك 15,000 ريال — 3 فواتير"
  │
  ├── "تم التسليم"
  │     → تصنيف: تأكيد
  │     → تحديث Delivery Note بهوية ceo-bot
  │     → رد واتساب: "تم تأكيد التسليم"
  │
  └── رسالة عامة
        → تخزين في brain فقط
```

**الطبقة 3 — Raven AI Bot (واجهة داخلية):**
بوت مساعد الفال يتطور:

| الحالي | المستهدف |
|--------|----------|
| قراءة فقط (8 functions) | قراءة + كتابة (15+ functions) |
| gpt-4o-mini | gpt-4o (أقوى في العربي) |
| يرد على أسئلة | يرد + ينفّذ أوامر |
| بدون ربط واتساب | يعرض محادثات واتساب من brain |

**Functions مقترحة للإضافة:**
```
# كتابة (مع write_access=true)
create_sales_order(customer, items)
create_payment_entry(customer, amount, mode)
create_leave_application(employee, from_date, to_date)
approve_material_request(name)

# قراءة متقدمة
get_customer_balance(customer)
get_overdue_invoices(days)
get_expiring_iqamas(days)
get_whatsapp_conversations(phone)
```

### المعمارية المستهدفة:
```
┌──────────────────────────────────────────────────────────────┐
│  السيرفر الرئيسي (187.124.4.197)                             │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │ ERPNext  │  │   n8n    │  │ Evolution│  │    Raven     │ │
│  │ v16      │  │ (الدماغ) │  │   API    │  │  + AI Bot    │ │
│  │          │  │          │  │          │  │              │ │
│  │ 6 مستخدم │  │ يتخذ     │  │ واتساب   │  │ واجهة       │ │
│  │ بوت      │  │ قرارات   │  │          │  │ المستخدم    │ │
│  │ (هوية)   │  │ ينفّذ    │  │          │  │ للبوت       │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘ │
│                                                              │
│  brain DB = ذاكرة كل شي (رسائل، هويات، محادثات)            │
└──────────────────────────────────────────────────────────────┘
```

### خطوات التنفيذ (عند الموافقة):

| # | المهمة | التفاصيل |
|---|--------|----------|
| B1 | تفعيل write_access في Raven AI Bot | مساعد الفال يقدر ينشئ مستندات |
| B2 | إضافة AI functions للكتابة | create_sales_order, create_payment_entry... |
| B3 | بناء n8n workflows ذكية | واتساب → AI تحليل → إنشاء مستندات |
| B4 | نقل API Keys البوتات لـ n8n | n8n يستخدم هوية البوت المناسب لكل عملية |
| B5 | ترقية Raven Bot لـ gpt-4o | فهم أعمق للعربي والسياق |
| B6 | مراجعة دور السيرفرات القائمة | تحديد أفضل استخدام لها بعد نقل المهام |

---

> هذا الملف يُحدّث عند كل قرار معماري كبير.
> آخر تحديث: 2026-02-27 — إضافة خطة إعادة بناء البوتات (تحت المراجعة)
