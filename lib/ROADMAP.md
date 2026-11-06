# Academic OS Roadmap

## نظرة عامة

Academic OS هو تطبيق Flutter مبني وفق Clean Architecture ليدعم إدارة المهام والمقررات الدراسية مع تخزين محلي مشفر.

## الهدف

المرحلة الأولى من المشروع تركز على:
- واجهة مستخدم بسيطة لإدارة المهام.
- تخزين محلي مشفر بـ SQLCipher.
- فصل واضح بين طبقات العرض والبيانات والمنطق.
- إمكانية التوسع لاحقًا لدعم الكورسات والذكاء الاصطناعي.

## بنية المشروع

lib/
  main.dart
  core/
    security/
      secure_storage_service.dart
  domain/
    entities/
      task_entity.dart
      course_entity.dart
    repositories/
      task_repository.dart
      course_repository.dart
    usecases/
      task_use_cases.dart
      course_use_cases.dart
  data/
    database/
      database_helper.dart
    models/
      task_model.dart
      course_model.dart
    datasources/
      task_local_data_source.dart
      course_local_data_source.dart
    repositories/
      task_repository_impl.dart
      course_repository_impl.dart
  presentation/
    home/
      home_screen.dart
    task/
      add_edit_task_screen.dart

## الطبقات والمسؤوليات

- `core`: خدمات مشتركة مثل التخزين الآمن لكلمة مرور قاعدة البيانات.
- `domain`: الكيانات (Entities)، العقود (Repositories)، وحالات الاستخدام (Use Cases).
- `data`: النماذج الخاصة بالتخزين، مصادر البيانات المحلية، وتنفيذ المستودعات.
- `presentation`: الشاشات والواجهة الرسومية.

## قواعد العمل

- واجهة المستخدم تتعامل مع `domain/usecases` فقط.
- لا تستورد `data/*` مباشرة داخل `presentation/*`.
- كل بيانات التخزين يجب أن تمر عبر:
  - `lib/data/models`
  - `lib/data/datasources`
  - `lib/data/repositories`
- كلمة مرور قاعدة البيانات تُخزن آمنًا في `flutter_secure_storage` عبر `SecureStorageService`.

## ملفات المرحلة الأولى الأساسية

- `lib/main.dart`
- `lib/core/security/secure_storage_service.dart`
- `lib/domain/entities/task_entity.dart`
- `lib/domain/repositories/task_repository.dart`
- `lib/domain/usecases/task_use_cases.dart`
- `lib/data/database/database_helper.dart`
- `lib/data/models/task_model.dart`
- `lib/data/datasources/task_local_data_source.dart`
- `lib/data/repositories/task_repository_impl.dart`
- `lib/presentation/home/home_screen.dart`
- `lib/presentation/task/add_edit_task_screen.dart`

## ملاحظات إضافية

- يوجد دعم مبدئي للمقررات (`courses`) في الطبقات، لكن الواجهة الحالية تركز على المهام.
- تم إضافة تحسينات سريعة للمهام الأكاديمية: الأولوية، التكرار، الملاحظات، والمهام المجدولة.
- الخطوة التالية تشمل: فلترة وفرز ذكي حسب الأولوية والتكرار، وتحسينات قاعدة البيانات واسترجاع الإشعارات.
- في حال إضافة وظائف جديدة، ابدأ دائمًا بتعريف الكيانات وواجهات المستودعات في `domain` قبل التغيير في `data` أو `presentation`.
  