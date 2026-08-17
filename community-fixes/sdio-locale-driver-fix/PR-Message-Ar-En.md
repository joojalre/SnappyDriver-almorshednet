# PR message (Arabic + English)

## Arabic

مرحبًا،  

سوينا تتبعًا محليًا لخلل التشغيل المتكرر في SDIO Origin 1.18.0.830 على جهاز ASUS (Windows 11 build 28000).  
النتيجة النهائية: **الأجهزة الآن سليمة (0 problem devices)**، لكن تم توثيق سلوكين يحتاجون تعديل سلوكي في السكربتات/التشغيل:

1) `Ret 1` و`LOGITECH_RAW_PDO`
- يظهر `Ret 1` رغم أن `jfunkraw.inf` يدخل DriverStore بنجاح (راجع `pnputil /enum-drivers`).
- هذا السلوك كان يتسبب بإعادة التشغيل التلقائي/التكرار دون داعٍ.

2) `unicode2ansi` و`sect not found`
- الرسالة تتغير بين كل تشغيل (`RTL8168H.ndi.NT (...)`) مما يشير إلى مشكلة تحويل ترميز أثناء وقت التشغيل.
- البيئة كانت على UTF-8 Beta، وموثّقة بترميز ANSI `65001`.

3) سبب تكرار النتائج الخاطئ
- تشغيل SDIO من غير working directory الصحيح يسبب اختلاف حل المسارات (`scripts`, `drivers`, `logs`) وسلوك غير متوقع.

### المقترحات
- اعتماد نجاح التشغيل بناءً على عدد أجهزة `ConfigManagerErrorCode != 0` بدل exit code.
- التحقق من `Ret 1` عبر DriverStore قبل إعادة المحاولة.
- تشغيل واحد فقط + بوابة توقف واضحة: إذا `0 drivers selected` و`0 problem devices` لا يوجد إعادة تشغيل/Loop.
- احتفاظ `DP_Misc_*.7z` ضمن `drivers\` وعدم عزلها افتراضيًا.

ملفات هذا PR:
- `community-fixes/sdio-locale-driver-fix/scripts/Run-SDIO-Safe.ps1`
- `community-fixes/sdio-locale-driver-fix/scripts/Verify-LocaleFix.ps1`
- `community-fixes/sdio-locale-driver-fix/scripts/AfterBoot-Verify.ps1`
- `community-fixes/sdio-locale-driver-fix/scripts/Fix-Locale-DisableUTF8Beta.ps1`
- `community-fixes/sdio-locale-driver-fix/scripts/Undo-ReEnableUTF8Beta.ps1`
- `community-fixes/sdio-locale-driver-fix/README.md`

## English

Hi team,

We reproduced and verified the SDIO Origin 1.18.0.830 behavior on an ASUS notebook (Windows 11 build 28000).
Current device state is clean (0 devices with `ConfigManagerErrorCode != 0`), but two behavior issues were confirmed:

1) `Ret 1` / `LOGITECH_RAW_PDO`
- `install64.exe` can return `Ret 1` while `jfunkraw.inf` is still staged successfully in DriverStore (`pnputil /enum-drivers`).
- This false signal caused redundant retries/loops.

2) `unicode2ansi` / `sect not found`
- Garbled section suffix changes across runs (`RTL8168H.ndi.NT (...)`), consistent with non-ASCII conversion behavior.
- System code page was in UTF-8 mode (`65001`), likely triggering conversion size/path lookup instability.

3) Working directory behavior
- Running SDIO from an unexpected CWD breaks relative path resolution for `scripts`, `drivers`, and `logs`, producing noisy/no-op behavior.

### Requested behavior fixes
- Prefer device-state based success (`ConfigManagerErrorCode`) over raw process exit code.
- Validate `Ret 1` with DriverStore before deciding to retry.
- Single-pass run + explicit stop gate:
  - if `0 drivers selected` and `0 problem devices`, do not loop.
- Keep misc packs in place by default (`DP_Misc_*.7z`).

This PR only adds investigation/verification tooling and operational guidance, so downstream users can reproduce and confirm behavior without extra tooling.
