# Care Note Assets - English Names

This package was generated from `돌봄수첩(7)-20261028T071607Z-1-001.zip`.

## Contents
- `assets/images/care_note/` : 68 SVGs and 68 matching PNGs, **136 assets** total.
- `care_note_asset_mapping.csv`: full original Korean-to-English file mapping.
- This guide.
- Finder metadata (`.DS_Store`) has been removed. Original image bytes have not been modified.

## Install in the Flutter project

1. Switch to the intended `care-note-ai` branch in your local repository.
2. Extract this ZIP **into the repository root**. Ensure paths become `assets/images/care_note/title.svg` etc., without an extra ZIP-named folder.
3. Add only this directory to `pubspec.yaml` under existing `flutter.assets` (preserve current entries):

```yaml
flutter:
  assets:
    - assets/images/care_note/
```

4. If `flutter_svg` is already configured, use `SvgPicture.asset('assets/images/care_note/...')` for scalable assets. Use PNG variants for shadow-sensitive frames and controls when the SVG version does not preserve the shadow.
5. Reuse existing app typography, navigation, data models, and theme. Keep text fields/date fields interactive; do not replace the entire screen with one image.

## Selected / unselected states
- `option_<name>_unselected.png` = unselected control (`클릭전`).
- `option_<name>_selected.png` = selected control (`클릭후`).
- The PNG variants preserve the supplied shadows and include their labels.
- Available options: good, normal, bad, low, bowel_normal, bowel_changed, medication_taken, medication_missed, unusual_yes, unusual_no, unusual_wandering, unusual_aggression, unusual_other, unusual_refusing_meals, unusual_repeated_questions, unusual_sleep_change, unusual_anxiety.

## Important
- The provided SVGs and PNGs are *UI fragments*, not full screen exports. Layout must be composed with Flutter widgets.
- Most PNG files are small native-sized UI elements. Prefer SVGs for scaling except where PNG fidelity is needed for shadows or embedded labels.
- Labels like `good`/`normal`/`bad` can be reused in different sections as the design requires; inspect the existing app/UI specification for accurate mapping.
- `medical_change` = doctor's visit or medication change; `unusual` = behavior different from usual.
- Design assets do not establish the existence of an AI API or database. Inspect the existing backend contracts before wiring real persistence or AI features.
