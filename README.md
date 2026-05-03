# Dinner Randomizer

A static dinner idea picker for a family of four. There is no backend; the page loads `data/dinners.json` in the browser and picks one random dinner at a time.

## Run locally

Serve the folder with any static file server:

```bash
python3 -m http.server 4173
```

Then open:

```text
http://localhost:4173/
```

Opening `index.html` directly from disk may prevent the browser from reading `data/dinners.json`, depending on browser security settings.

## Add dinners

Edit `data/dinners.json`. Each dinner can already carry future image and recipe fields:

```json
{
  "id": "example-dinner",
  "name": "Example Dinner",
  "description": "Short family-friendly description.",
  "mainIngredients": ["ingredient one", "ingredient two"],
  "image": null,
  "recipeUrl": null,
  "notes": "Optional serving note."
}
```
