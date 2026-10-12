# تفعيل Nova AI داخل تطبيق 𝐇𝐚𝐦𝐨

## طريقة إضافة مفتاح Gemini بأمان

لا تضع مفتاح Gemini داخل أي ملف ولا تقسّمه لتجاوز فحص GitHub. الطريقة الصحيحة هي إضافة GitHub Actions Secret باسم:

```text
GEMINI_API_KEY
```

من داخل المستودع الخاص:

```text
Settings → Secrets and variables → Actions → New repository secret
```

ملف التطبيق يقرأه من متغير البناء هنا:

```text
lib/core/config/gemini_config.dart
```

والـWorkflow يمرره تلقائيًا إلى Flutter باستخدام:

```text
--dart-define=GEMINI_API_KEY
```

## البناء عبر Krinry

شغّل Workflow من:

```text
Actions → krinry Build → Run workflow
```

ثم اختر `release` و`apk` أو `appbundle`.

للبناء المحلي:

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_NEW_KEY
```

## تنبيه أمني

الاتصال المباشر من Flutter إلى Gemini يجعل المفتاح قابلًا للاستخراج من APK حتى لو كان Secret أثناء البناء. استخدم مفتاحًا مخصصًا للتطبيق، قيّده حسب تطبيق Android، وحدد الحصة اليومية. ألغِ المفتاح القديم الذي تم إرساله سابقًا.
