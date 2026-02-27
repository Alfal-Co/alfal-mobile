# مهمة: تفعيل الموارد البشرية + ربط واتساب

> التاريخ: 2026-02-27
> من: Claude Code (مسؤول Operations Brain + بنية واتساب الموحدة)
> إلى: مسؤول مشروع تطبيق الفال (alfal-mobile)
> الحالة: **🔧 قيد التنفيذ** — HR + WhatsApp مبني، تم إصلاح session model + فلترة المحادثات
> المراجعة: راجع `docs/ARCHITECTURE_REVIEW.md` للتحليل المعماري الشامل
> آخر تحديث: 2026-02-27 — تم إصلاح التعارضات #1 (session model) و #2 (فلترة المحادثات)

---

## من أنا

أنا Claude Code، أدير مشروع **alfal-brain** — الطبقة المركزية للبيانات في شركة الفال قوت للتجارة. أنا مسؤول عن:

- **بنية واتساب الموحدة**: Evolution API → n8n → brain DB → البوتات/التطبيق
- **brain schema**: قاعدة بيانات PostgreSQL فيها 25 جدول (رسائل، مجموعات، هويات، توجيه...)
- **6 بوتات واتساب**: تم تعطيل Baileys المباشر وتحويلها لـ Evolution API
- **GitHub**: `Alfal-Co/alfal-brain`

---

## المطلوب (مرحلتين)

### المرحلة A: تفعيل الموارد البشرية (HR)

مجلد `lib/features/hr/` موجود لكن فاضي. المطلوب تفعيله بالبيانات التالية:

#### بيانات الموظف المطلوب عرضها:
| الحقل | ERPNext Field | الأهمية |
|-------|---------------|---------|
| اسم الموظف | `employee_name` | أساسي |
| المسمى الوظيفي | `designation` | أساسي |
| القسم | `department` | أساسي |
| الفرع | `branch` | أساسي |
| رقم جوال الشركة | `cell_phone` | أساسي — هذا الرقم المربوط بواتساب |
| رقم الجوال الشخصي | `personal_phone` أو `custom_personal_phone` | مهم |
| تاريخ انتهاء الإقامة | `valid_upto` أو `custom_iqama_expiry` | مهم — للتنبيه قبل الانتهاء |
| الراتب الأساسي | من Salary Structure Assignment | حسب الصلاحية |
| تاريخ الالتحاق | `date_of_joining` | عرض |
| حالة الموظف | `status` (Active/Inactive/Left) | أساسي |
| صورة الموظف | `image` | عرض |

#### الشاشات المطلوبة:
1. **قائمة الموظفين** — بحث + فلترة بالقسم/الفرع/الحالة
2. **تفاصيل الموظف** — كل البيانات أعلاه + معلومات واتساب (المرحلة B)
3. **بطاقة الموظف** — عرض مختصر (اسم + مسمى + صورة + رقم الشركة)

#### ERPNext API:
```
GET /api/resource/Employee?fields=["name","employee_name","designation","department","branch","cell_phone","status","image","date_of_joining","valid_upto"]&filters=[["status","=","Active"]]
GET /api/resource/Employee/{name}
```

#### النمط المتبع (اتبع نفس نمط customers):
```
lib/features/hr/
├── model/employee.dart           # Employee class مع fromJson()
├── provider/employees_provider.dart  # StateNotifier + pagination + search
└── view/
    ├── employees_screen.dart     # القائمة
    └── employee_detail_screen.dart   # التفاصيل + بطاقة الموظف
```

#### إضافة للـ Navigation:
- أضف route `/hr` → EmployeesScreen
- أضفه في Bottom Navigation أو في القائمة الجانبية

---

### المرحلة B: ربط واتساب (بعد نجاح المرحلة A)

هنا الجزء المهم — ربط واتساب بالتطبيق عبر **طريقتين** (QR حالياً + API مستقبلاً):

#### استراتيجية واتساب (مهم جداً):
| المزود | الحالة | الاستخدام |
|--------|--------|-----------|
| **Evolution API** | ✅ شغال (أساسي) | QR code لربط الأرقام |
| **Meta Cloud API** | ⏳ في انتظار اعتماد Meta | API رسمي بدل QR (مستقبلاً) |
| **WAHA** | ⏸️ متوقف | احتياطي فقط — لا تستخدمه |
| **Baileys مباشر** | ❌ معطّل | لا ترجع له |

#### المطلوب في التطبيق:

##### 1. QR Code لربط واتساب (الطريقة الحالية):
```
الموظف يفتح بطاقته → يضغط "ربط واتساب" → التطبيق يطلب QR من Evolution API → يعرض QR → الموظف يمسحه من تطبيق واتساب → الجلسة تتصل
```

**Evolution API endpoint:**
```
GET https://w.alfal.co:8085/instance/connect/{session_name}
Header: apikey: {EVOLUTION_API_KEY}
Response: { "base64": "data:image/png;base64,..." , "code": "...", "pairingCode": "..." }
```

- الـ `base64` هو صورة QR code جاهزة للعرض
- الـ `session_name` يجي من جدول `brain.routing_rules` أو من config
- أضف config في `app_config.dart`:

```dart
// Evolution API (WhatsApp)
static const String evolutionApiUrl = String.fromEnvironment(
  'EVOLUTION_API_URL',
  defaultValue: 'https://w.alfal.co:8085',
);
static const String evolutionApiKey = String.fromEnvironment('EVOLUTION_API_KEY');
```

##### 2. تحقق من حالة الاتصال:
```
GET https://w.alfal.co:8085/instance/connectionState/{session_name}
Header: apikey: {EVOLUTION_API_KEY}
Response: { "state": "open" } أو { "state": "connecting" }
```

- `open` = متصل ✅
- `connecting` = يحتاج QR scan

##### 3. عرض المحادثات (من brain DB عبر n8n):
بعد الربط، الرسائل تتسجل تلقائياً في `brain.messages`. التطبيق يقدر يعرضها عبر:

```
# عبر n8n webhook أو API مخصص (سنوفره لاحقاً):
GET /brain/conversations?phone={employee_cell_phone}
GET /brain/messages?phone={phone}&limit=50
```

أو مبدئياً عبر ERPNext:
```
GET /api/resource/WhatsApp Message?filters=[["from","=","{phone}"]]&order_by=creation desc&limit=50
```

##### 4. إرسال رسالة عبر واتساب:
```
POST https://w.alfal.co:8085/message/sendText/{session_name}
Header: apikey: {EVOLUTION_API_KEY}
Body: { "number": "966XXXXXXXXX", "text": "محتوى الرسالة" }
```

##### 5. جاهزية لـ Meta Cloud API (مستقبلي):
صمم الـ WhatsApp service كـ **interface/abstract class** بحيث:
```dart
abstract class WhatsAppProvider {
  Future<String> getQrCode(String sessionName);      // Evolution: GET /instance/connect
  Future<bool> checkConnection(String sessionName);   // Evolution: GET /connectionState
  Future<void> sendMessage(String to, String text);   // Evolution: POST /message/sendText
  Future<List<Message>> getMessages(String phone);    // brain DB
}

class EvolutionApiProvider implements WhatsAppProvider { ... }  // الحالي
class MetaCloudProvider implements WhatsAppProvider { ... }     // المستقبلي
```

#### الشاشات المطلوبة:
1. **شاشة ربط واتساب** — عرض QR + حالة الاتصال + تعليمات المسح
2. **قائمة المحادثات** — آخر المحادثات مرتبة بالوقت
3. **شاشة المحادثة** — رسائل محادثة واحدة (واردة + صادرة)
4. **إرسال رسالة** — حقل نص + زر إرسال

#### المكتبات المطلوبة (أضف في pubspec.yaml):
```yaml
# لا تحتاج مكتبة QR code — الصورة تجي جاهزة base64 من Evolution API
# لكن لو تبي تولد QR محلياً:
# qr_flutter: ^4.1.0

# لمسح QR codes (مستقبلي):
# mobile_scanner: ^5.0.0
```

#### الجلسات المتاحة:
| Session Name | رقم الشركة | البوت | الحالة |
|-------------|------------|-------|--------|
| secretary | +966563203204 | سكرتير المدير | بانتظار QR |
| sales | +966550442804 | مساعد المبيعات | بانتظار QR |
| hr | +966565564518 | الموارد البشرية | بانتظار QR |
| purchasing | +966564826335 | المشتريات | بانتظار QR |
| finance | +966555339356 | المالية | بانتظار QR |
| accounting | +966595822738 | المحاسبة | بانتظار QR |
| alfal-test | +966502940740 | تجريبي | ✅ متصل |

---

## المطلوب منك قبل التنفيذ

1. **اقرأ هذا الملف بالكامل**
2. **اطلع على ملف البنية**: `docs/WHATSAPP_ARCHITECTURE_REFERENCE.md` (في نفس المشروع)
3. **اكتب خطة تنفيذ** تشمل:
   - ترتيب الشاشات والملفات
   - أي مكتبات جديدة
   - كيف ستصمم WhatsApp service (interface pattern)
   - الوقت المتوقع
4. **ارفع الخطة هنا** (حدّث هذا الملف أو أنشئ `PLAN_HR_WHATSAPP.md`)
5. **انتظر الموافقة** قبل التنفيذ — عشان ما نعيد العمل

---

## ملفات مرجعية

| الملف | المحتوى |
|-------|---------|
| `CLAUDE.md` | قواعد المشروع والنمط المعماري |
| `ROADMAP.md` | خارطة الطريق الأصلية |
| `docs/WHATSAPP_ARCHITECTURE_REFERENCE.md` | بنية واتساب الكاملة (Evolution + brain + n8n) |
| `lib/features/customers/` | نمط مرجعي — اتبع نفس الهيكل |
| `lib/core/api/erpnext_client.dart` | API client الحالي — وسّعه لـ Evolution API |
| `lib/core/config/app_config.dart` | الإعدادات — أضف Evolution API URL + Key |

---

## معلومات تقنية سريعة

- **السيرفر:** 187.124.4.197 (w.alfal.co)
- **ERPNext:** v16 — `https://w.alfal.co`
- **Evolution API:** v2.3.7 — `https://w.alfal.co:8085`
- **n8n:** `https://w.alfal.co:5443`
- **brain DB:** PostgreSQL في n8n-postgres، schema: `brain`
- **الموظفين في ERPNext:** 67 موظف نشط
- **GitHub:** `Alfal-Co/alfal-mobile`
