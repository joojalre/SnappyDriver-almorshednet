# SDIO Ret 1 / Unicode Locale Fix Pack

## الهدف

حلّات عملية لتثبيت SDIO Origin بدون إعادة محاولات غير ضرورية بعد ظهور:

- `unicode2ansi()/ERROR_INSUFFICIENT_BUFFER`
- `sect not found`
- `Ret 1` من `LOGITECH_RAW_PDO`/`install64.exe`

> هذه الحزمة لا تعدّل ملف SDIO الأساسي نفسه. هي أدوات تحقق وتشخيص + تسلسل تشغيل آمن للمساعدة في فحص الحالة وتوثيق السبب.

## الملفات

```text
community-fixes/sdio-locale-driver-fix/
  README.md
  scripts/
    Run-SDIO-Safe.ps1
    Verify-LocaleFix.ps1
    AfterBoot-Verify.ps1
    Fix-Locale-DisableUTF8Beta.ps1
    Undo-ReEnableUTF8Beta.ps1
  PR-Message-Ar-En.md
```

## Usage

> ملاحظة: بعض المسارات في السكربتات مكتوبة كمثال لمسار الجهاز المستخدم أثناء التحقيق. غيّرها لمسارك المحلي.

```powershell
cd C:\YourPath\SnappyDriver-almorshednet\community-fixes\sdio-locale-driver-fix\scripts
.\Verify-LocaleFix.ps1      # تحقق سريع + فحص Log بدون تثبيت
.\Run-SDIO-Safe.ps1 -DryRun # فحص بدون تعديل drivers
```

### For actual install run

```powershell
cd C:\YourPath\SDIO_1.18.0.830
.\scripts\Run-SDIO-Safe.ps1 -ScriptFile 'scripts\update-no-hid.txt'
```

- يشغل SDIO مرة واحدة فقط.
- يعتمد على `ConfigManagerErrorCode` بدل exit code فقط.
- يمنع `retry loop` عندما لا توجد أجهزة معطوبة فعلًا.

## كيف ترفع هذا على GitHub للمشروع

1. أنشئ fork.
2. غيّر الملفات حسب جهازك.
3. Commit وادفع على فرعك.
4. افتح Pull Request في `SnappyDriver-almorshednet`.
5. في PR body، استخدم الملف:
   [PR-Message-Ar-En.md](/C:/Users/vip/Projects/SnappyDriver-almorshednet/community-fixes/sdio-locale-driver-fix/PR-Message-Ar-En.md)

## عربي سريع

نشر هذه الملفات مع PR يساعد أي شخص ينزّل المشروع يفهم فورًا:

- شنو المشكلة
- شنو سببها
- شنو تغييرات التحقيق
- كيف يكررها بأمان على جهازه

إذا عندكم نظام يحدّث SDIO رسميًا داخل بيئة صيانة ويندوز، تقدرون تضعون هذا المجلد كمرجع لخطوات الـ triage قبل إغلاق أي ticket.
*** End Patch
