# Agent Notes

This is a static dinner randomizer web app. There is no build step and no backend.

## Structure

- `index.html`: app markup.
- `styles.css`: all styling and responsive layout.
- `app.js`: loads dinner data, picks random dinners, manages Back/Next history, and swaps dish images.
- `data/dinners.json`: source of truth for dinner options.
- `assets/dishes/*.jpg`: dish-specific images referenced by `data/dinners.json`.
- `assets/dinner-table.jpg`: fallback image used if a dinner has no image.

## Run Locally

Serve the project folder with a static server:

```bash
python3 -m http.server 4173
```

Open:

```text
http://localhost:4173/
```

Do not rely on opening `index.html` directly from disk, because browser `fetch()` may block `data/dinners.json` under `file://`.

## Data Model

Each dinner in `data/dinners.json` currently uses:

```json
{
  "id": "stable-kebab-case-id",
  "name": "Display Name",
  "description": "Short dinner description.",
  "mainIngredients": ["ingredient one", "ingredient two"],
  "image": "assets/dishes/example.jpg",
  "recipeUrl": null,
  "notes": "Optional serving note."
}
```

Keep IDs stable unless intentionally replacing a dish. If adding or replacing images, keep `image` paths relative to the project root.

## Testing

Basic syntax and data checks:

```bash
node -c app.js
node -e "JSON.parse(require('fs').readFileSync('data/dinners.json','utf8')); console.log('json ok')"
```

Full data/image validation:

```bash
node - <<'NODE'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('data/dinners.json', 'utf8'));
const missingFiles = data.filter((d) => d.image && !fs.existsSync(d.image));
const missingImages = data.filter((d) => !d.image);
const duplicateIds = data.map((d) => d.id).filter((id, i, ids) => ids.indexOf(id) !== i);
console.log({ count: data.length, missingImages: missingImages.length, missingFiles: missingFiles.map((d) => d.id), duplicateIds });
NODE
```

Expected current state:

- `100` dinners.
- Every dinner has an image.
- No duplicate IDs.
- No missing image files.

After UI changes, reload the in-app browser at `http://localhost:4173/` and check the console for errors.

## Image Workflow

Dish images are generated bitmap assets, then saved as JPGs in `assets/dishes/`. Keep generated images practical and family-dinner oriented:

- photorealistic
- horizontal 16:9-ish composition
- bright natural light
- simple home dining table
- no people, hands, text, logos, or watermarks

When replacing a dish image, leave old generated originals untouched. It is okay for unused old JPGs to remain in `assets/dishes/` unless the user explicitly asks to delete them.

## User Preference

The user does not like green peas. Do not add dishes, descriptions, ingredients, notes, or generated images that include green peas. Chickpeas are acceptable and are a different ingredient.
