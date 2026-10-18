# Dart analyzer fix

The reported `package:flutter/material.dart` and relative-import diagnostics are analyzer/package-resolution errors, not evidence that `create_ad_screen.dart` has 100+ independent Dart syntax errors.

Run from the project root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\FIX_VSCODE_ANALYZER.ps1
```

Then in VS Code:
1. Open the **ZankoSwap** folder itself.
2. Ensure the Flutter extension is installed.
3. Run `Dart: Restart Analysis Server`.
4. If needed, use `Developer: Reload Window`.

The project source already contains the referenced files:
- `lib/features/ads/data/ad_repository.dart`
- `lib/core/models/ad_campaign.dart`

and `create_ad_screen.dart` imports them from the correct relative paths.
