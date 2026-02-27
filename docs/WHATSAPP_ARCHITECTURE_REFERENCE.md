# بنية واتساب الموحدة — مرجع لتطبيق الجوال

> هذا الملف مرجع تقني (endpoints + أمثلة). للمراجعة المعمارية الشاملة: `docs/ARCHITECTURE_REVIEW.md`
> المصدر الأساسي: `Alfal-Co/alfal-brain`

## البنية العامة

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────┐
│  مستخدم      │────▶│  Evolution API    │────▶│  n8n        │
│  واتساب      │◀────│  w.alfal.co:8085  │     │  WA Router  │
└──────────────┘     └──────────────────┘     └──────┬──────┘
                                                      │
                                          ┌───────────┼───────────┐
                                          ▼           ▼           ▼
                                    brain.messages  brain.groups  ERPNext
                                    brain.raw_events              WhatsApp Message
```

## استراتيجية المزودين

| المزود | الحالة | متى يُستخدم |
|--------|--------|-------------|
| **Evolution API** | ✅ أساسي | كل عمليات واتساب الآن (QR code) |
| **Meta Cloud API** | ⏳ قادم | عند اعتماد التطبيق من Meta (API رسمي بدل QR) |
| **WAHA** | ⏸️ متوقف | لا تستخدمه — احتياطي طوارئ فقط |
| **Baileys مباشر** | ❌ معطّل | لا ترجع له نهائياً |

**مهم:** صمم WhatsApp service كـ interface عشان التبديل بين Evolution و Meta يكون سهل مستقبلاً.

### نموذج الجلسات (مهم جداً)

```
❌ خطأ:  كل موظف → جلسة خاصة (wa_EMP-0001)  ← ما فيه 67 رقم هاتف!
✅ صحيح: كل قسم → جلسة واحدة (sales, hr, purchasing...)
```

الربط:
```
Employee.department → routing_rules.session_name
  "Sales"      → "sales"      (+966550442804)
  "HR"         → "hr"         (+966565564518)
  "Purchasing" → "purchasing"  (+966564826335)
  "Finance"    → "finance"    (+966555339356)
  "Accounting" → "accounting" (+966595822738)
  أي قسم آخر  → "secretary"  (+966563203204)  ← الافتراضي
```

---

## Evolution API — الـ Endpoints المطلوبة للتطبيق

### Base URL
```
https://w.alfal.co:8085
```

### Authentication
```
Header: apikey: {EVOLUTION_API_KEY}
```
الـ API Key يُخزّن في environment variable — لا تكتبه في الكود.

### 1. جلب QR Code لربط واتساب
```http
GET /instance/connect/{session_name}
```
**Response:**
```json
{
  "pairingCode": "XXXX-XXXX",
  "code": "2@base64string...",
  "base64": "data:image/png;base64,iVBORw0KGgo...",
  "count": 1
}
```
- `base64` — صورة QR جاهزة للعرض مباشرة (PNG)
- `pairingCode` — كود رقمي بديل (لو ما يقدر يمسح QR)
- `count` — عدد المحاولات

### 2. فحص حالة الاتصال
```http
GET /instance/connectionState/{session_name}
```
**Response:**
```json
{ "instance": { "state": "open" } }
```
القيم: `open` (متصل), `connecting` (يحتاج QR), `close` (مفصول)

### 3. إرسال رسالة نصية
```http
POST /message/sendText/{session_name}
Content-Type: application/json

{
  "number": "966502940740",
  "text": "مرحباً"
}
```

### 4. إرسال صورة
```http
POST /message/sendMedia/{session_name}
Content-Type: application/json

{
  "number": "966502940740",
  "mediatype": "image",
  "media": "https://example.com/image.jpg",
  "caption": "وصف الصورة"
}
```

### 5. إرسال ملف
```http
POST /message/sendMedia/{session_name}
Content-Type: application/json

{
  "number": "966502940740",
  "mediatype": "document",
  "media": "https://example.com/file.pdf",
  "fileName": "فاتورة.pdf"
}
```

### 6. جلب معلومات الجلسات
```http
GET /instance/fetchInstances
```

---

## الجلسات المسجلة

| Session Name | الرقم | البوت | الحالة |
|-------------|-------|-------|--------|
| `alfal-test` | +966502940740 | تجريبي | ✅ متصل |
| `secretary` | +966563203204 | سكرتير المدير (bot-1) | بانتظار QR |
| `sales` | +966550442804 | مساعد المبيعات (bot-2) | بانتظار QR |
| `hr` | +966565564518 | الموارد البشرية (bot-3) | بانتظار QR |
| `purchasing` | +966564826335 | المشتريات (bot-4) | بانتظار QR |
| `finance` | +966555339356 | المالية (bot-heavy) | بانتظار QR |
| `accounting` | +966595822738 | المحاسبة (bot-light) | بانتظار QR |

---

## قراءة الرسائل

### الطريقة 1: من ERPNext (متاحة الآن)
```http
GET /api/resource/WhatsApp Message
  ?filters=[["from","=","+966502940740"]]
  &fields=["name","from","to","message","type","content_type","creation","status"]
  &order_by=creation desc
  &limit_page_length=50
```

### الطريقة 2: من brain DB عبر n8n (قيد التطوير)
```http
POST https://w.alfal.co:5443/webhook/brain-api
Content-Type: application/json

{
  "action": "get_messages",
  "phone": "+966502940740",
  "limit": 50
}
```
هذا الـ endpoint سيُبنى لاحقاً. الطريقة 1 تكفي مبدئياً.

---

## تدفق ربط واتساب في التطبيق

```
[شاشة تفاصيل الموظف]
        │
        ▼
  زر "ربط واتساب"
        │
        ▼
  GET /instance/connectionState/{session}
        │
        ├── state = "open" → ✅ "واتساب مربوط" (عرض المحادثات)
        │
        └── state != "open" → GET /instance/connect/{session}
                                    │
                                    ▼
                              عرض QR code (base64 image)
                              + عرض pairing code كبديل
                              + تعليمات: "افتح واتساب → الأجهزة المرتبطة → مسح QR"
                                    │
                                    ▼
                              Timer: كل 5 ثواني → GET /connectionState
                                    │
                                    ├── state = "open" → ✅ نجح! → عرض المحادثات
                                    └── state != "open" → انتظر (أو أعد QR بعد انتهاء الصلاحية)
```

---

## نمط التصميم المقترح

```dart
// lib/core/api/whatsapp_provider.dart
abstract class WhatsAppProvider {
  Future<QrCodeResult> getQrCode(String sessionName);
  Future<ConnectionState> checkConnection(String sessionName);
  Future<SendResult> sendText(String sessionName, String to, String text);
  Future<SendResult> sendMedia(String sessionName, String to, String mediaUrl, String type);
  Future<List<ChatMessage>> getMessages(String phone, {int limit = 50});
}

// lib/core/api/evolution_provider.dart
class EvolutionProvider implements WhatsAppProvider {
  final Dio _dio;
  final String baseUrl;  // https://w.alfal.co:8085
  final String apiKey;   // from environment
  // ... implementation using Evolution API endpoints above
}

// lib/core/api/meta_cloud_provider.dart (مستقبلي)
class MetaCloudProvider implements WhatsAppProvider {
  // ... implementation using Meta Cloud API (when approved)
}
```

---

## ملاحظات أمنية

1. **API Key** لـ Evolution API يُخزّن في environment variable فقط
2. **لا تعرض API Key** في الكود أو في Git
3. **الأرقام** تُطبّع بصيغة `+966XXXXXXXXX` (بدون 05)
4. **WAHA** متوقف — لا تستخدم أي endpoint خاص به
5. **الرسائل** تمر كلها عبر n8n وتُسجّل في brain — لا ترسل مباشرة إلا عبر Evolution API
