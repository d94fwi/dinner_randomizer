# Agent Notes

This is a static dinner randomizer web app with a native SwiftUI iOS client that reuses the shared dinner data and image assets. There is no backend. GitHub Pages publishes only the assembled static web site from GitHub Actions.

## Structure

- `web/index.html`: web app markup.
- `web/styles.css`: all web styling and responsive layout.
- `web/app.js`: loads dinner data, picks random dinners, manages Back/Next history, and swaps dish images.
- `shared/data/dinners.json`: source of truth for dinner options.
- `shared/assets/dishes/*.jpg`: dish-specific images referenced by `shared/data/dinners.json`.
- `shared/assets/dinner-table.jpg`: fallback image used if a dinner has no image.
- `ios/DinnerRandomizer/DinnerRandomizer.xcodeproj`: native iOS app project.
- `ios/DinnerRandomizer/DinnerRandomizer/`: SwiftUI app source.
- `ios/DinnerRandomizer/DinnerRandomizerTests/`: native data/resource tests.
- `.github/workflows/deploy-pages.yml`: validates and publishes only the assembled web app to GitHub Pages from `master`.
- UI language strings live in `UI_TEXT` in `web/app.js`.

## iOS App Design

The iOS app is a native Swift / SwiftUI implementation, not a web view. It should stay aligned with the web app visually and behaviorally while using iOS-native controls.

- `ContentView.swift`: main SwiftUI interface, including toolbar search/language controls, the dinner card, ingredient chips, note accent bar, bottom Back/Next controls, and swipe gestures.
- `ViewModels/DinnerRandomizerViewModel.swift`: loads dinners, owns selected language, manages current/previous/upcoming dinner queues, prevents very recent repeats, and exposes localized view state.
- `Services/DinnerResourceLoader.swift`: reads bundled `data/dinners.json` and resolves bundled image paths like `assets/dishes/example.jpg`.
- `Models/Dinner.swift`: decodes the shared JSON model and produces `LocalizedDinner` values with English fallback behavior.
- `Models/AppLanguage.swift`: supported languages, flag emoji, saved language key, and device-language detection.
- `Models/AppCopy.swift`: native UI copy for English, Swedish, Norwegian, and Polish.
- `Views/DinnerImageView.swift`: bundled image rendering with a fallback placeholder.

The Xcode project links `../../shared/data` as bundled `data/` resources and `../../shared/assets` as bundled `assets/` resources. Keep JSON image paths in the same deployed web form (`assets/dishes/...`) so both the web app and iOS app can resolve them without client-specific data.

Navigation behavior:

- Next uses a shuffled upcoming queue and appends the current dinner to Back history.
- Back pops from the previous-dinner stack.
- The current, previous, and upcoming dinner cards are rendered together during a swipe so the adjacent card is visible while dragging.
- Swipe transitions move the entire card as one unit. When a drag commits, the adjacent card finishes moving into place, then the view model swaps the dinner with animations disabled and resets the drag offset invisibly. Avoid adding per-subview transitions inside the card because that can make the image, labels, and ingredient section animate independently.

Language behavior mirrors the web app:

- Supported UI/content languages are English (`en`), Swedish (`sv`), Norwegian (`no`), and Polish (`pl`).
- Manual language choice is stored under `dinnerRandomizerLanguage`, matching the web storage key.
- The language selector is a SwiftUI `Menu`; include flag emoji next to language names when adding or changing languages.
- Dinner text localization comes from `Dinner.localized(for:fallbackDescription:)`; keep English top-level fields as the fallback.

The web app supports two static layouts:

- Source/local layout: serve the repository root and open `/web/`; `web/app.js` reads `../shared/data/dinners.json` and `../shared/assets/...`.
- Published layout: GitHub Actions copies `web/` to `_site/`, then copies `shared/data/` to `_site/data/` and `shared/assets/` to `_site/assets/`; the deployed app reads `data/dinners.json` and `assets/...`.

## Run Locally

Serve the repository root with a static server:

```bash
python3 -m http.server 4173
```

Open:

```text
http://localhost:4173/web/
```

Do not rely on opening `web/index.html` directly from disk, because browser `fetch()` may block `shared/data/dinners.json` under `file://`.

## Data Model

Each dinner in `shared/data/dinners.json` currently uses:

```json
{
  "id": "stable-kebab-case-id",
  "name": "Display Name",
  "description": "Short dinner description.",
  "mainIngredients": ["ingredient one", "ingredient two"],
  "image": "assets/dishes/example.jpg",
  "notes": "Optional serving note.",
  "translations": {
    "sv": {
      "name": "Swedish display name",
      "description": "Swedish short dinner description.",
      "mainIngredients": ["Swedish ingredient one", "Swedish ingredient two"],
      "notes": "Swedish optional serving note."
    },
    "no": {
      "name": "Norwegian display name",
      "description": "Norwegian short dinner description.",
      "mainIngredients": ["Norwegian ingredient one", "Norwegian ingredient two"],
      "notes": "Norwegian optional serving note."
    },
    "pl": {
      "name": "Polish display name",
      "description": "Polish short dinner description.",
      "mainIngredients": ["Polish ingredient one", "Polish ingredient two"],
      "notes": "Polish optional serving note."
    }
  }
}
```

Keep IDs stable unless intentionally replacing a dish. If adding or replacing images, keep `image` paths in deployed web form, for example `assets/dishes/example.jpg`. In source, that resolves to `shared/assets/dishes/example.jpg`; in the published GitHub Pages site, that resolves to `assets/dishes/example.jpg`.

## Language Handling

Supported UI/content languages are English (`en`), Swedish (`sv`), Norwegian (`no`), and Polish (`pl`).

- English dinner text stays in the top-level `name`, `description`, `mainIngredients`, and `notes` fields.
- Swedish, Norwegian, and Polish dinner text lives in `translations.sv`, `translations.no`, and `translations.pl`.
- `web/app.js` chooses localized dinner fields at render time and falls back to the top-level English fields if a translation is missing.
- The language selector buttons are in `web/index.html`; add a `data-language` button when adding a language.
- UI copy, button labels, page titles, pluralized idea counts, and language button accessible names are all in `UI_TEXT` in `web/app.js`.
- Manual language choice is stored in `localStorage` under `dinnerRandomizerLanguage`.
- If there is no saved manual choice, the app defaults to Swedish for `sv`/`sv-*` browser languages, Norwegian for `no`/`no-*`, `nb`/`nb-*`, or `nn`/`nn-*`, Polish for `pl`/`pl-*`, and English otherwise.
- When translating dish names, use natural target-language wording, but keep common borrowed dish names in English or their original form when that reads better, such as Pulled Pork, Ramen, Banh Mi, Tikka Masala, or Fish Pie.

## Testing

Basic syntax and data checks:

```bash
node -c web/app.js
node -e "JSON.parse(require('fs').readFileSync('shared/data/dinners.json','utf8')); console.log('json ok')"
```

Full data/image validation:

```bash
node - <<'NODE'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('shared/data/dinners.json', 'utf8'));
const missingFiles = data.filter((d) => d.image && !fs.existsSync(`shared/${d.image}`));
const missingImages = data.filter((d) => !d.image);
const duplicateIds = data.map((d) => d.id).filter((id, i, ids) => ids.indexOf(id) !== i);
const incomplete = (lang) => data.filter((d) => {
  const tx = d.translations?.[lang];
  return !tx || !tx.name || !tx.description || !Array.isArray(tx.mainIngredients) || tx.mainIngredients.length === 0 || typeof tx.notes !== 'string';
}).map((d) => d.id);
console.log({
  count: data.length,
  missingImages: missingImages.length,
  missingFiles: missingFiles.map((d) => d.id),
  duplicateIds,
  incompleteSv: incomplete('sv'),
  incompleteNo: incomplete('no'),
  incompletePl: incomplete('pl')
});
NODE
```

Expected current state:

- `100` dinners.
- Every dinner has an image.
- No duplicate IDs.
- No missing image files.
- Every dinner has complete Swedish, Norwegian, and Polish translations.

After UI changes, reload the in-app browser at `http://localhost:4173/web/` and check the console for errors.

iOS build verification:

```bash
xcodebuild -project ios/DinnerRandomizer/DinnerRandomizer.xcodeproj -scheme DinnerRandomizer -destination generic/platform=iOS -derivedDataPath /private/tmp/DinnerRandomizerDerivedData CODE_SIGNING_ALLOWED=NO build
```

iOS data/resource tests can be run from Xcode against an iOS simulator when CoreSimulator is available. In restricted automation environments, a generic iOS build is the usual smoke test.

## Image Workflow

Dish images are generated bitmap assets, then saved as JPGs in `shared/assets/dishes/`. Keep generated images practical and family-dinner oriented:

- photorealistic
- horizontal 16:9-ish composition
- bright natural light
- simple home dining table
- no people, hands, text, logos, or watermarks

When replacing a dish image, leave old generated originals untouched. It is okay for unused old JPGs to remain in `shared/assets/dishes/` unless the user explicitly asks to delete them.

## User Preference

The user does not like green peas. Do not add dishes, descriptions, ingredients, notes, or generated images that include green peas. Chickpeas are acceptable and are a different ingredient.
