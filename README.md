# Academic OS

Academic OS هو نظام إدارة أكاديمية مبني على Flutter ويهدف إلى تنظيم حياة الطالب الجامعي داخل تطبيق واحد. يركز المشروع على دمج المهام الدراسية، المقررات، الجداول، التنبيهات، والتقييم الأكاديمي في واجهة موحدة وسهلة الاستخدام، مع اعتماد على التخزين المحلي الآمن والتصميم المعماري المنظم.

يُعد هذا المشروع مثالاً عملياً لتطبيق أكاديمي حديث يوازن بين سهولة الاستخدام والهيكل المعماري المرن. ويعتمد على نموذج خفيف من Clean Architecture، حيث يتم فصل طبقات الـ Core، الـ Domain، الـ Data، و الـ Presentation. ويستند التطبيق إلى قاعدة بيانات محلية مع خدمات أمنية ومتعددة، بهدف دعم الطالب في إدارة حياته الأكاديمية اليومية بشكل أكثر فاعلية.

## لماذا هذا النظام؟

غالباً ما يحتاج الطالب الجامعي إلى إدارة العديد من الجوانب في وقت واحد، مثل:

- المهام الدراسية والتسليمات والمواعيد النهائية
- المقررات الدراسية، أسماء المحاضرين، وأوقات المحاضرات
- تقييم الأداء الأكاديمي وحساب المعدل المتوقع
- ترتيب وقت الدراسة والجداول الأسبوعية
- مواعيد الاختبارات والامتحانات
- تنبيهات تذكيرية قبل الموعد

يعالج Academic OS هذه التحديات من خلال بوابة أكاديمية موحدة تجمع هذه الوظائف داخل تطبيق محلي، مع إمكانية التوسع في المستقبل لدعم تقارير أكثر تعقيداً أو أدوات ذكاء اصطناعي متقدمة داخل النظام.

---

## Core Features

استناداً إلى الشاشات والوظائف الموجودة فعلياً في مجلد `lib/`، يحتوي التطبيق على هذه المزايا الأساسية:

### 1. إدارة المهام الدراسية
- إنشاء مهمة جديدة، تعديلها، وحذفها
- تصنيف المهام حسب النوع، الأولوية، والتكرار
- ربط كل مهمة بمادة دراسية محددة
- دعم التذكيرات عبر إشعارات محلية
- عرض المهام حسب الحالة: الكل، المكتملة، المعلقة، أو المتأخرة

### 2. إدارة المقررات الدراسية
- إضافة مقررات دراسية، تعديلها، وحذفها
- حفظ بيانات كل مادة: الاسم، الكود، المحاضر، الساعات، الفصل، والملاحظات
- إدارة تفاصيل كل مقرر، بما في ذلك المواد والمستندات المرتبطة
- عرض قائمة المقررات مع البحث والفلترة

### 3. نظام تسجيل الدخول وحماية التطبيق
- شاشة تسجيل الدخول وتسجيل المستخدم محلياً
- دعم تسجيل الدخول عبر Google
- قفل التطبيق باستخدام نظام PIN و/أو المصادقة البيومترية
- تخزين البيانات الحساسة داخل `flutter_secure_storage`
- إعدادات قفل التطبيق من شاشة الخصوصية والأمان

### 4. الجداول الدراسية والتخطيط الأكاديمي
- عرض جدول أسبوعي للمحاضرات
- إدارة أيام ومواعيد المحاضرات
- دعم تنبيهات المحاضرات القريبة
- تخطيط نوعية الوقت المتاح للدراسة

### 5. الخطة الدراسية والتركيز
- شاشة Focus Timer لمتابعة جلسات الدراسة
- شاشة Study Planner لتوزيع خطة المذاكرة
- تنظيم الوقت بناءً على أولويات الطالب

### 6. اختبارات ومعدلات الطلاب
- إدارة امتحانات المقررات مع تواريخها وملاحظاتها
- شاشة Grade Simulator لتوقع النتائج أو محاكاة المعدل
- شاشة GPA Calculator و Target Grade Calculator
- شاشة Grade Distribution لعرض التوزيع أو التمثيل المرئي للدرجات

### 7. لوحة المعلومات الأكاديمية والذكاء الاصطناعي
- خدمة Academic Dashboard لإحصاء الحالة الأكاديمية العامة
- شاشة Academic AI Assistant التي تستقبل أسئلة الطالب وتقدم اقتراحات مباشرة
- دعم أسئلة عملية مثل: وقت المذاكرة، أقرب اختبار، أو توقع المعدل

### 8. الإشعارات والتنبيهات المحلية
- تنبيهات لمهام وموعد نهائي
- تنبيهات لمحاضرات قريبة
- دعم `flutter_local_notifications` و `timezone` لتحديد الوقت بدقة

### 9. إعدادات التطبيق والنسخ الاحتياطي
- إعدادات عامة للتطبيق
- شاشة النسخ الاحتياطي والتصدير
- دعم اللغة العربية/الإنجليزية
- دعم الوضع الفاتح/الداكن

---

## Architecture & Tech Stack

### Architecture

المشروع يتبع نموذجاً خفيفاً من Clean Architecture، حيث يتم تقسيم المسؤوليات إلى طبقات واضحة:

- `lib/core/` — الخدمات المشتركة: الأمن، التهيئة، التنبيهات، المنصات، الثيم، والخدمات الأكاديمية
- `lib/domain/` — الكيانات، الواجهات، وحالات الاستخدام (Use Cases)
- `lib/data/` — النماذج، مصادر البيانات المحلية، المستودعات، وقاعدة البيانات
- `lib/presentation/` — كل شاشات UI ومكونات العرض
- `lib/providers/` — إدارة الحالة باستخدام Riverpod
- `lib/features/` — وحدات خاصة ومكونات إضافية

### التقنيات والمكتبات المستخدمة فعلياً

استناداً إلى `pubspec.yaml`، هذه هي التبعيات الفعلية الموجودة في المشروع:

#### Framework and runtime
- Flutter SDK: `>=3.0.0 <4.0.0`
- Dart SDK: مرتبط مع Flutter

#### UI and app foundation
- `flutter`
- `flutter_localizations`
- `cupertino_icons`

#### State management
- `flutter_riverpod: ^2.6.1`

#### Local storage and security
- `sqflite: ^2.3.3`
- `sqflite_common_ffi: ^2.3.3`
- `sqflite_common_ffi_web: ^1.0.0`
- `shared_preferences: ^2.3.0`
- `flutter_secure_storage: ^9.0.0`
- `crypto: ^3.0.6`

#### Auth and device security
- `google_sign_in: ^6.2.1`
- `local_auth: ^2.2.0`

#### Notifications and scheduling
- `flutter_local_notifications: ^18.0.0`
- `timezone: ^0.9.4`

#### File and document support
- `file_picker: ^10.2.0`
- `flutter_pdfview: ^1.2.3`
- `pdf_text: ^0.5.0`

#### Development tools
- `flutter_test`
- `flutter_lints: ^5.0.0`

> ملاحظة مهمة: بينما تذكر بعض الملفات في المشروع SQLCipher في التوثيق، فإن التبعيات الحالية الفعلية في `pubspec.yaml` توضح أنه يتم استخدام SQLite عبر `sqflite` مع دعم FFI و `flutter_secure_storage`، وهذا هو الواقع الحالي في الكود.

### قاعدة البيانات المحلية

يتم إدارة قاعدة البيانات المحلية عبر `DatabaseHelper` في `lib/data/database/database_helper.dart`، باستخدام:

- SQLite عبر `sqflite`
- إعدادات FFI للتطبيقات desktop وweb
- إنشاء الجداول الأساسية للمهام، المقررات، الامتحانات، جدول المحاضرات، والمواد الدراسية
- ترقية قاعدة البيانات عند تحديث الإصدار (`onUpgrade`)
- تخزين كلمة المرور أو البيانات الحساسة عبر `SecureStorageService`

---

## Directory Structure

```text
AcademicOS/
├─ android/
├─ ios/
├─ linux/
├─ macos/
├─ windows/
├─ web/
├─ test/
├─ lib/
│  ├─ core/
│  │  ├─ academic/
│  │  ├─ initializer/
│  │  ├─ notifications/
│  │  ├─ platform/
│  │  ├─ security/
│  │  ├─ services/
│  │  ├─ theme/
│  │  └─ widgets/
│  ├─ data/
│  │  ├─ database/
│  │  ├─ datasources/
│  │  ├─ models/
│  │  └─ repositories/
│  ├─ domain/
│  │  ├─ ai/
│  │  ├─ entities/
│  │  ├─ repositories/
│  │  └─ usecases/
│  ├─ features/
│  │  └─ exam/
│  ├─ presentation/
│  │  ├─ about/
│  │  ├─ ai_assistant/
│  │  ├─ auth/
│  │  ├─ course/
│  │  ├─ courses/
│  │  ├─ exam/
│  │  ├─ focus/
│  │  ├─ gpa/
│  │  ├─ grade_simulator/
│  │  ├─ home/
│  │  ├─ notifications/
│  │  ├─ onboarding/
│  │  ├─ schedule/
│  │  ├─ screens/
│  │  ├─ settings/
│  │  ├─ study_plan/
│  │  ├─ task/
│  │  └─ tasks/
│  ├─ providers/
│  ├─ main.dart
│  ├─ ROADMAP.md
│  └─ ...
├─ analysis_options.yaml
├─ pubspec.yaml
├─ README.md
├─ AGENTS.md
├─ ARCHITECTURE.md
├─ .gitignore
├─ .metadata
└─ .idea/
```

بعض الملفات الرئيسية في المشروع:

- `lib/main.dart` — نقطة تشغيل التطبيق وتركيب الاعتماديات
- `lib/presentation/home/home_screen.dart` — الشاشة الرئيسية ولوحة التحكم
- `lib/presentation/task/add_edit_task_screen.dart` — إضافة/تعديل المهام
- `lib/presentation/course/course_list_screen.dart` — قائمة المقررات
- `lib/presentation/ai_assistant/academic_ai_screen.dart` — شاشة المساعد الأكاديمي
- `lib/data/database/database_helper.dart` — إعداد قاعدة البيانات المحلية
- `lib/core/security/secure_storage_service.dart` — تخزين كلمات المرور بشكل آمن
- `lib/core/academic/academic_assistant_service.dart` — منطق المساعد الأكاديمي

---

## Getting Started

### 1. استنساخ المشروع

```bash
git clone <repository-url>
cd AcademicOS
```

### 2. تثبيت الحزم

```bash
flutter pub get
```

### 3. تشغيل التطبيق

```bash
flutter run
```

### 4. التشغيل على منصات محددة

#### Android
```bash
flutter run -d android
```

#### Web
```bash
flutter run -d chrome
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### Linux
```bash
flutter run -d linux
```

### 5. التحقق من الجودة

```bash
flutter analyze
flutter test
```

---

## ملاحظات المشروع والحالة الحالية

- التطبيق يعمل بواجهة عربية بشكل افتراضي، مع دعم لواجهة إنجليزية في بعض المكونات
- التصميم الحالي يركز بشكل كبير على إدارة الطالب الأكاديمي بشكل محلي
- التطبيق يعتمد على قاعدة بيانات محلية وليس خادم خارجي، ما يجعله مناسباً للاستخدام الذاتي في بيئات بلا إنترنت
- بنية المشروع تسمح بالتوسع في نقاط مثل: تقارير أكاديمية أكثر عمقاً، إدارة حضور/غياب أكثر دقة، أو نموذج ذكاء اصطناعي متقدم

---

## Summary

Academic OS هو تطبيق أكاديمي محلي مصمم لمساعدة الطالب على تنظيم حياته الدراسية بطريقة ذكية ومنظمة. يجمع بين إدارة المهام والمقررات، التذكيرات، والمعدلات، مع بنية واضحة وقاعدة بيانات محلية وآمنة، في تجربة Flutter متكاملة تناسب إدارة الحياة الجامعية اليومية.
