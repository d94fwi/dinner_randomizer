# Dinner Randomizer

A dinner idea picker for a family of four. There is no backend; the web app loads the shared dinner JSON in the browser, and the native iOS app bundles the same JSON and images into the app.

This is a vibe coded application. Most of the dinners suggestions are AI generated, as well as the images.
Use at your own risk.

## Structure

```text
web/
  index.html
  styles.css
  app.js

ios/
  DinnerRandomizer/
    DinnerRandomizer.xcodeproj
    DinnerRandomizer/
    DinnerRandomizerTests/

shared/
  data/dinners.json
  assets/
    dinner-table.jpg
    dishes/*.jpg

.github/workflows/
  deploy-pages.yml
```

`shared/data/dinners.json` is the source of truth for dinner ideas. The web app reads from `shared/` when served from source, and GitHub Pages publishes a copied layout where `data/` and `assets/` sit next to `index.html`.

The iOS app is a native Swift / SwiftUI app, not a web view. Its Xcode project includes `shared/data` as bundled `data/` resources and `shared/assets` as bundled `assets/` resources, so the same image paths used by the web app, such as `assets/dishes/example-dinner.jpg`, also resolve inside the iOS app bundle.

## Run from GitHub Pages

Run [Dinner Randomizer](https://d94fwi.github.io/dinner_randomizer/) here.

## Run locally

Serve the repository root with any static file server:

```bash
python3 -m http.server 4173
```

Then open:

```text
http://localhost:4173/web/
```

Opening `web/index.html` directly from disk may prevent the browser from reading `shared/data/dinners.json`, depending on browser security settings.

## Run the iOS app

Open the native project in Xcode:

```text
ios/DinnerRandomizer/DinnerRandomizer.xcodeproj
```

Select the `DinnerRandomizer` scheme and run it on an iPhone simulator or device. The app uses SwiftUI and bundled resources; it does not load the web app.

To smoke-test a native build from the command line:

```bash
xcodebuild -project ios/DinnerRandomizer/DinnerRandomizer.xcodeproj -scheme DinnerRandomizer -destination generic/platform=iOS -derivedDataPath /private/tmp/DinnerRandomizerDerivedData CODE_SIGNING_ALLOWED=NO build
```

## GitHub Pages Deployment

GitHub Pages is deployed by `.github/workflows/deploy-pages.yml` whenever changes are pushed to `master`, or when the workflow is run manually from the GitHub Actions tab.

The workflow publishes only a temporary `_site/` folder with this shape:

```text
_site/
  index.html
  styles.css
  app.js
  data/dinners.json
  assets/
```

To use it, set the repository's GitHub Pages source to `GitHub Actions` in `Settings -> Pages`.

## Add dinners

Edit `shared/data/dinners.json`. Each dinner can include a dish image and optional translations:

```json
{
  "id": "example-dinner",
  "name": "Example Dinner",
  "description": "Short family-friendly description.",
  "mainIngredients": ["ingredient one", "ingredient two"],
  "image": "assets/dishes/example-dinner.jpg",
  "notes": "Optional serving note.",
  "translations": {
    "sv": {
      "name": "Swedish display name",
      "description": "Swedish short description.",
      "mainIngredients": ["Swedish ingredient one"],
      "notes": "Swedish optional serving note."
    }
  }
}
```

Image paths are written as deployed web paths such as `assets/dishes/example-dinner.jpg`. In source, that file lives at `shared/assets/dishes/example-dinner.jpg`.

English text lives in the top-level fields. Swedish, Norwegian, and Polish text lives in `translations.sv`, `translations.no`, and `translations.pl`. Both clients fall back to the English fields when localized dinner text is missing.

## iOS design notes

The native app is organized around a small SwiftUI view model and resource loader:

- `DinnerResourceLoader` reads bundled `data/dinners.json` and resolves bundled image files.
- `DinnerRandomizerViewModel` owns loading, language selection, Back history, the upcoming dinner queue, and localized display state.
- `ContentView` renders a compact card-style UI with a toolbar language menu, Google recipe search, ingredient chips, a note accent bar, bottom Back/Next buttons, and horizontal swipe navigation.

During a swipe, the previous/current/next cards are rendered together so the adjacent card appears while dragging. When the swipe commits, the visible card finishes sliding into place and the underlying dinner is swapped without a second entrance animation.

## Validate

```bash
node -c web/app.js
node -e "JSON.parse(require('fs').readFileSync('shared/data/dinners.json','utf8')); console.log('json ok')"
xcodebuild -project ios/DinnerRandomizer/DinnerRandomizer.xcodeproj -scheme DinnerRandomizer -destination generic/platform=iOS -derivedDataPath /private/tmp/DinnerRandomizerDerivedData CODE_SIGNING_ALLOWED=NO build
```
