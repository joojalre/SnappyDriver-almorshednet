# Feature Request: Add Scan / Re-Scan / Update controls in SDIO UI

## Context

The current project already provides a strong CLI/workflow path, but technicians and technicians-in-field still need a one-click workflow for repeated maintenance.

## Why this request is needed

- `Scan` is needed to run a safe first-pass check from a known state.
- `Re-Scan` is needed after quick fixes or package refresh.
- `Update` is needed to quickly check SDIO updates and restart workflow without using command-line scripts.

## Expected behavior

1. **Scan button**
   - Runs one full detection pass.
   - Does not require manual command-line entry.
2. **Re-Scan button**
   - Re-runs scan after drivers were refreshed or staged.
   - Uses same safe logic currently expected in wrapper workflow.
3. **Update button**
   - Checks local version vs latest release.
   - Offers direct action to download/update package.

## UX acceptance criteria

- No accidental loops from transient `Ret 1` return codes.
- Clear status message: scan started / finished / no changes / problems remain.
- Works in portable usage (USB repair workflow) with minimal clicks.

## Request

Please consider adding these controls directly in the UI in a future release so users can avoid manual script-driven workflows.

---

## طلب ميزة: أزرار Scan / Re-Scan / Update داخل الواجهة

- نحتاج زر `Scan` لفحص مبدئي واضح.
- نحتاج زر `Re-Scan` لإعادة فحص سريعة بعد إصلاح بسيط.
- نحتاج زر `Update` لفحص تحديثات SDIO وتحديث النسخة بسهولة.
- هذا يحسن شغل الفنيين، ويقلل التكرار اليدوي، ويخلي التصحيح/المراجعة أسرع.

إذا أوافق، أقدر أضيف مسودة واجهة بسيطة في سكربت وسيط (launcher) كـ workaround مؤقت لحين إضافة الزر الرسمي.
