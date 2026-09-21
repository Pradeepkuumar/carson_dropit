# Project instructions

## Permission before changes

Do not edit, create, or delete any file in this project without the user's explicit go-ahead first. Before making a change, describe what you're about to do (files, the nature of the change) and wait for the user to confirm — even for small or clearly-implied fixes. This applies to code changes specifically; read-only research (reading files, searching, running analyzers) does not need prior permission.

## Text styles

Always use the project's custom text styles for UI text instead of raw `TextStyle(...)` widgets.

- Custom styles live in `lib/utils/text_style_util.dart` (`AppTextStyle` class, e.g. `AppTextStyle.tsCustom(color, fontSize)`), built on `GoogleFonts.inter`/`GoogleFonts.manrope`.
- Default to `utils.tvCustom(text, color, fontSize, {textAlignment, maxLines})` (in `lib/utils/utils.dart`) for text — it's the established app-wide helper. Pass the plain phone-base `fontSize`; it already scales up on tablet internally via `responsiveFontSize` (`context.isTablet ? size * 1.35 : size`), so don't also wrap the size in a manual `isTablet ? a : b` or `.sp` — that double-scales it. `textAlignment` defaults to `TextAlign.center`; pass `TextAlign.left` explicitly for text inside a `Row`/`Expanded` that should stay left-aligned.
- **Known behavior**: `tvCustom` always renders plain `AppColors.white` when `Get.isDarkMode` is true, ignoring whatever color you pass, and its font weight is fixed at `w600`. This is the app's existing dark-mode convention (confirmed with the user for the dashboard rework) — don't fight it by trying to preserve a specific muted/secondary grey or a non-w600 weight through `tvCustom`. Just pass the light-mode color; dark mode is handled for you.
- Use `AppTextStyle.tsCustom(...).copyWith(...)` directly (bypassing `tvCustom`) only when you genuinely need per-state control `tvCustom` can't give you — e.g. a font weight that must vary with selection state (see the bottom-nav tab labels in `rider_dashboard.dart`), not merely "the weight in the design isn't 600".

## Currency

The app's currency is **QAR** (Qatari Riyal). Whenever an amount is displayed to the user, show it as `QAR <amount>` (currency code prefixed, with a space), e.g. `QAR 1,240` — not a bare number and not a symbol like `₹` or `$`.

## Theming and responsiveness

Every UI screen or component built or edited must work correctly in both **dark and light theme**, and be **responsive on both mobile and tablet** screen sizes.

- Theme: don't hardcode colors that break in dark mode. Follow existing patterns — check `Get.isDarkMode` and branch colors inline at the point of use (e.g. `Get.isDarkMode ? AppColors.white : AppColors.black`), as already done throughout the app (`AppTextStyle`, `utils.tvCustom`, `rider_dashboard.dart`, etc.). Reuse existing constants in `lib/utils/colors.dart` (`AppColors`) for both the light and dark side of the branch wherever one already fits; only add a brand-new constant to `colors.dart` (never an inline hex literal in a screen file) when nothing existing works.
- Responsiveness: don't hardcode fixed pixel sizes/layouts that only work on phones. Branch inline with `context.isPhone` (or `!context.isPhone` for tablet) combined with `flutter_screenutil`'s `.sp`/`.w`/`.h`/`.r`, matching the existing precedent (`context.isPhone ? 264.sp : 360.0.sp` in `_buildProfileMenuOverlay` in `rider_dashboard.dart`) so layouts adapt on tablets.
- **Do not wrap this in a per-screen tokens/theme class.** Every screen should use the same plain, inline pattern above — a bespoke helper class defined inside one screen's file doesn't scale across the app and should be avoided. If a shared helper is genuinely warranted, it belongs in `lib/utils/utils.dart` (alongside `responsiveFontSize`) as an app-wide utility, not as a one-off class local to a screen.
- Before considering UI work done, mentally (or actually, via the `run` skill) check both theme modes and both a phone-sized and tablet-sized viewport.
