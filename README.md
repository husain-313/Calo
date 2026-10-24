# Calo

A personal, free iOS calorie & nutrition tracker — built from scratch in SwiftUI.
No subscription, no locked features.

## Features
- **Daily budget** — calorie goal from Mifflin‑St Jeor TDEE + goal pace, with a progress ring.
- **Food diary** — breakfast / lunch / dinner / snacks, per‑day navigation.
- **Food search** — Open Food Facts (millions of products, free).
- **Barcode scanner** — camera scan → instant nutrition lookup.
- **Custom foods** — add your own foods and quick calories.
- **Macros** — protein / carbs / fat goals and tracking.
- **Weight** — log + chart + goal line, writes to Apple Health.
- **Exercise** — MET‑based calorie burn, optional add‑back to the budget.
- **Water** — daily goal ring and quick adds.
- **Fasting** — intermittent‑fasting timer (12/14/16/18/20/24h).
- **Reports** — 14‑day calories and weight trend.
- **Apple Health** — reads steps / active energy, writes weight.

## Build
No Mac needed locally — the IPA is built in CI (GitHub Actions, macOS runner).

1. Push to GitHub.
2. The **Build IPA** workflow runs on every push to `main` and on `v*` tags.
3. Download the **Calo-unsigned-ipa** artifact, then sideload (Sideloadly / AltStore) which re‑signs it.

Local project generation (Mac only): `xcodegen generate && open Calo.xcodeproj`.

## Data & attribution
Food data: [Open Food Facts](https://world.openfoodfacts.org) (ODbL). Nutrition values are
estimates for personal tracking only and are not medical advice.

## Roadmap
- Snap It‑style photo food recognition (on‑device Vision / food‑classifier model).
- Recipe builder with per‑serving nutrition.
- Meal plans & favorites, home‑screen widgets, notifications/reminders.
- USDA FoodData Central as a second search source.
