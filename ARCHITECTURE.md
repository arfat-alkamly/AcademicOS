
## الطبقات

### Core
- `SecureStorageService`
- مسؤول عن حفظ واسترجاع كلمة مرور قاعدة البيانات المشفرة.

### Domain
- `TaskEntity`
- `TaskRepository`
- `TaskUseCases`
- الفصل بين منطق الأعمال وطبقة البيانات.

### Data
- `TaskModel`
- `DatabaseHelper`
- `TaskLocalDataSource`
- `TaskRepositoryImpl`
- تخزين SQLite عبر sqflite؛ ملف قاعدة البيانات غير مشفر حالياً، وتحويل من/إلى `TaskEntity`.

### Presentation
- `HomeScreen`
- `AddEditTaskScreen`
- التفاعل مع المستخدم عبر `TaskUseCases` فقط.

## القواعد
- كل كود قاعدة بيانات يجب أن يكون في `data/database`.
- كل نموذج تخزين يجب أن يكون في `data/models`.
- كل واجهة Repository في `domain/repositories`.
- لا تستورد `data` مباشرة من `presentation` إلا عبر واجهات `usecases`.
- الكيانات في `domain/entities` تمثل بيانات الأعمال فقط.

## المرحلة الأولى
- CRUD للمهام:
  - إضافة مهمة
  - تعديل مهمة
  - حذف مهمة
  - عرض قائمة مهام
- تخزين محلي عبر SQLite/sqflite؛ تشفير قاعدة البيانات بـ SQLCipher غير منفذ حالياً
- استخدام `flutter_secure_storage` لحفظ مفتاح التشفير
- فصل المسؤوليات مع إمكانية التوسع لاحقاً للجدول الدراسي والذكاء الاصطناعي

## ملاحظات
- `lib/services/database_helper.dart` يجب أن يُزال إذا كان موجوداً في الهيكل القديم.
- `lib/models/task_model.dart` يجب أن يُحذف واستبدل بـ `lib/data/models/task_model.dart`.
- `main.dart` يبني الطبقات ويصلح `TaskUseCases` إلى `HomeScreen`.


# Academic OS Architecture

## الهدف
بناء المرحلة الأولى من Academic OS وفق Clean Architecture مع دعم التخزين المحلي المشفر وطبقة عمليات واضحة.

## المبدأ
- واجهة المستخدم (Presentation) لا تعرف مصادر البيانات.
- Domain يحتوي على الكيانات وواجهات المستودعات وحالات الاستخدام.
- Data يحتوي على تفاصيل التخزين وتحويل البيانات من/إلى النموذج.
- Core يحتوي على خدمات مشتركة مثل التخزين الآمن والأمن.

## هيكل المجلدات
lib/
main.dart
core/
security/
secure_storage_service.dart
domain/
entities/
task_entity.dart
repositories/
task_repository.dart
usecases/
task_use_cases.dart
data/
database/
database_helper.dart
models/
task_model.dart
datasources/
task_local_data_source.dart
repositories/
task_repository_impl.dart
presentation/
home/
home_screen.dart
task/
add_edit_task_screen.dart


## الطبقات

### Core
- `SecureStorageService`
- مسؤول عن حفظ واسترجاع كلمة مرور قاعدة البيانات المشفرة.

### Domain
- `TaskEntity`
- `TaskRepository`
- `TaskUseCases`
- الفصل بين منطق الأعمال وطبقة البيانات.

### Data
- `TaskModel`
- `DatabaseHelper`
- `TaskLocalDataSource`
- `TaskRepositoryImpl`
- تخزين SQLite عبر sqflite؛ ملف قاعدة البيانات غير مشفر حالياً، وتحويل من/إلى `TaskEntity`.

### Presentation
- `HomeScreen`
- `AddEditTaskScreen`
- التفاعل مع المستخدم عبر `TaskUseCases` فقط.

## القواعد
- كل كود قاعدة بيانات يجب أن يكون في `data/database`.
- كل نموذج تخزين يجب أن يكون في `data/models`.
- كل واجهة Repository في `domain/repositories`.
- لا تستورد `data` مباشرة من `presentation` إلا عبر واجهات `usecases`.
- الكيانات في `domain/entities` تمثل بيانات الأعمال فقط.

## المرحلة الأولى
- CRUD للمهام:
  - إضافة مهمة
  - تعديل مهمة
  - حذف مهمة
  - عرض قائمة مهام
- تخزين محلي عبر SQLite/sqflite؛ تشفير قاعدة البيانات بـ SQLCipher غير منفذ حالياً
- استخدام `flutter_secure_storage` لحفظ مفتاح التشفير
- فصل المسؤوليات مع إمكانية التوسع لاحقاً للجدول الدراسي والذكاء الاصطناعي

## ملاحظات
- `lib/services/database_helper.dart` يجب أن يُزال إذا كان موجوداً في الهيكل القديم.
- `lib/models/task_model.dart` يجب أن يُحذف واستبدل بـ `lib/data/models/task_model.dart`.
- `main.dart` يبني الطبقات ويصلح `TaskUseCases` إلى `HomeScreen`.
