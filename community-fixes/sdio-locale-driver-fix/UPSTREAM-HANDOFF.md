# SDIO Locale Fix Pack — Upstream Handoff (v1.1.2)

## Arabic (مختصر)

هذا المجلد هو نسخة التعديلات النهائية اللي سويناها لتثبيت SDIO Origin بشكل نظيف على الحالة المشاهدة:

- إصلاح دورة التحذير `unicode2ansi` + `sect not found` المرتبط بتحويل الترميز أثناء تشغيل `UTF-8 Beta`.
- منع حلقة إعادة التشغيل الخاطئة الناتجة عن `Ret 1` الخاص بـ `LOGITECH_RAW_PDO`.
- تشغيل واحد قوي عبر `Run-SDIO-Safe.ps1` بدل إعادة التشغيل اللامنتهي.
- أدوات تحقق جاهزة للمختبرات (post-boot verify + ACP check).
- واجهة تشغيل بسيطة مع أزرار `Scan / Re-Scan / Update` في `SDIO-QuickLauncher.ps1`.

الرابط الرسمي للحزمة:
- **Download:** https://github.com/joojalre/SnappyDriver-almorshednet/releases/tag/v1.1.2-sdio-locale-fix-pack

الرسالة الجاهزة للإرسال للمشروع الأصلي:
- https://github.com/Snappy-Driver-Download/.github/issues/1

## English (short)

This folder contains the final upstream handoff artifacts for SDIO Origin behavior issues:

- Fixed locale conversion instability in `unicode2ansi` / `sect not found` workflows.
- Removed false retry loops caused by `LOGITECH_RAW_PDO` `Ret 1` when devices are already healthy.
- One-pass execution flow in `Run-SDIO-Safe.ps1` (no redundant reruns).
- Verification helpers (`AfterBoot-Verify`, `Verify-LocaleFix`) for reproducible checks.
- Technician launcher (`SDIO-QuickLauncher.ps1`) with `Scan`, `Re-Scan`, `Update`.

Primary package:
- **Download:** https://github.com/joojalre/SnappyDriver-almorshednet/releases/tag/v1.1.2-sdio-locale-fix-pack

Upstream tracking thread:
- https://github.com/Snappy-Driver-Download/.github/issues/1

## Copy-ready message for upstream PR/Issue

**Arabic + English**

مرحبًا، حنا جهزنا pack جاهز للتكامل ويفتح نفس المشكلة/الحل بشكل reproducible.
Hello, we prepared a reproducible community handoff pack for the SDIO Origin behavior fixes.

- Repo fork: https://github.com/joojalre/SnappyDriver-almorshednet
- Latest release: https://github.com/joojalre/SnappyDriver-almorshednet/releases/tag/v1.1.2-sdio-locale-fix-pack
- Latest commit: https://github.com/joojalre/SnappyDriver-almorshednet/commit/96e7399

المجلد المعني: `community-fixes/sdio-locale-driver-fix`

Includes:
- `Run-SDIO-Safe.ps1` (single-pass runner + stop gate)
- `SDIO-QuickLauncher.ps1` (Scan / Re-Scan / Update)
- `Verify-LocaleFix.ps1` (ACP/GetACP + parser-safe checks)
- `AfterBoot-Verify.ps1`
- `Fix-Locale-DisableUTF8Beta.ps1`, `Undo-ReEnableUTF8Beta.ps1`

If there is an official application source repo, we can open exact cherry-pick PRs there.
