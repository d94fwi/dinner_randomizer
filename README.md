# Dinner Randomizer

A static dinner idea picker for a family of four. There is no backend; the web app loads the shared dinner JSON in the browser and picks one random dinner at a time.

This is a vibe coded application. Most of the dinners suggestions are AI generated, as well as the images.
Use at your own risk.

## Structure

```text
web/
  index.html
  styles.css
  app.js

shared/
  data/dinners.json
  assets/
    dinner-table.jpg
    dishes/*.jpg

.github/workflows/
  deploy-pages.yml
```

`shared/data/dinners.json` is the source of truth for dinner ideas. The web app reads from `shared/` when served from source, and GitHub Pages publishes a copied layout where `data/` and `assets/` sit next to `index.html`.

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

Edit `shared/data/dinners.json`. Each dinner can include a dish image:

```json
{
  "id": "example-dinner",
  "name": "Example Dinner",
  "description": "Short family-friendly description.",
  "mainIngredients": ["ingredient one", "ingredient two"],
  "image": "assets/dishes/example-dinner.jpg",
  "notes": "Optional serving note."
}
```

Image paths are written as deployed web paths such as `assets/dishes/example-dinner.jpg`. In source, that file lives at `shared/assets/dishes/example-dinner.jpg`.

## Validate

```bash
node -c web/app.js
node -e "JSON.parse(require('fs').readFileSync('shared/data/dinners.json','utf8')); console.log('json ok')"
```
