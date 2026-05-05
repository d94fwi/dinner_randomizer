const SHARED_ASSET_PREFIX = window.location.pathname.includes("/web/") ? "../shared/" : "";
const DATA_URL = `${SHARED_ASSET_PREFIX}data/dinners.json`;
const FALLBACK_IMAGE = `${SHARED_ASSET_PREFIX}assets/dinner-table.jpg`;
const LANGUAGE_STORAGE_KEY = "dinnerRandomizerLanguage";
const RECENT_REPEAT_BUFFER_SIZE = 10;

const LANGUAGE_FLAGS = {
  en: "🇬🇧",
  no: "🇳🇴",
  pl: "🇵🇱",
  sv: "🇸🇪",
};

const UI_TEXT = {
  en: {
    pageTitle: "Dinner Randomizer",
    appTitle: "Dinner Randomizer",
    languageLabel: "Language",
    languages: {
      en: "English",
      no: "Norwegian",
      pl: "Polish",
      sv: "Swedish",
    },
    loadingIdeas: "Loading ideas",
    loadingDinnerName: "Loading dinner ideas...",
    loadingDescription: "The app is reading the dinner list.",
    mainIngredients: "Main ingredients",
    navigationLabel: "Dinner navigation",
    back: "Back",
    next: "Next dinner idea",
    recipeSearch: "Search recipe on Google",
    recipeSearchTerm: "recipe",
    noIdeasLoaded: "No ideas loaded",
    noDinnerIdeasYet: "No dinner ideas yet",
    noIdeasDescription: "Add dinners to shared/data/dinners.json to start picking.",
    dataUnavailable: "Data unavailable",
    loadErrorName: "Could not load dinner ideas",
    loadErrorDescription: "Serve these files from any static host so the browser can read the dinner data.",
    fallbackDescription: "A family dinner idea.",
    ideaCount(count) {
      return `${count} idea${count === 1 ? "" : "s"}`;
    },
  },
  sv: {
    pageTitle: "Dagens middag",
    appTitle: "Dagens middag",
    languageLabel: "Språk",
    languages: {
      en: "Engelska",
      no: "Norska",
      pl: "Polska",
      sv: "Svenska",
    },
    loadingIdeas: "Laddar idéer",
    loadingDinnerName: "Laddar middagsidéer...",
    loadingDescription: "Appen läser in middagslistan.",
    mainIngredients: "Huvudingredienser",
    navigationLabel: "Middagsnavigering",
    back: "Tillbaka",
    next: "Nästa middagsidé",
    recipeSearch: "Sök recept på Google",
    recipeSearchTerm: "recept",
    noIdeasLoaded: "Inga idéer laddade",
    noDinnerIdeasYet: "Inga middagsidéer ännu",
    noIdeasDescription: "Lägg till middagar i shared/data/dinners.json för att börja lotta.",
    dataUnavailable: "Data saknas",
    loadErrorName: "Kunde inte ladda middagsidéer",
    loadErrorDescription: "Servera filerna från valfri statisk server så att webbläsaren kan läsa middagsdatan.",
    fallbackDescription: "En middagsidé för familjen.",
    ideaCount(count) {
      return `${count} ${count === 1 ? "idé" : "idéer"}`;
    },
  },
  no: {
    pageTitle: "Dagens middag",
    appTitle: "Dagens middag",
    languageLabel: "Språk",
    languages: {
      en: "Engelsk",
      no: "Norsk",
      pl: "Polsk",
      sv: "Svensk",
    },
    loadingIdeas: "Laster ideer",
    loadingDinnerName: "Laster middagsideer...",
    loadingDescription: "Appen leser middagslisten.",
    mainIngredients: "Hovedingredienser",
    navigationLabel: "Middagsnavigasjon",
    back: "Tilbake",
    next: "Neste middagsidé",
    recipeSearch: "Søk etter oppskrift på Google",
    recipeSearchTerm: "oppskrift",
    noIdeasLoaded: "Ingen ideer lastet",
    noDinnerIdeasYet: "Ingen middagsideer ennå",
    noIdeasDescription: "Legg til middager i shared/data/dinners.json for å begynne å trekke.",
    dataUnavailable: "Data mangler",
    loadErrorName: "Kunne ikke laste middagsideer",
    loadErrorDescription: "Server filene fra en statisk server slik at nettleseren kan lese middagsdataene.",
    fallbackDescription: "En middagsidé for familien.",
    ideaCount(count) {
      return `${count} ${count === 1 ? "idé" : "ideer"}`;
    },
  },
  pl: {
    pageTitle: "Dzisiejszy obiad",
    appTitle: "Dzisiejszy obiad",
    languageLabel: "Język",
    languages: {
      en: "Angielski",
      no: "Norweski",
      pl: "Polski",
      sv: "Szwedzki",
    },
    loadingIdeas: "Ładowanie pomysłów",
    loadingDinnerName: "Ładowanie pomysłów na obiad...",
    loadingDescription: "Aplikacja wczytuje listę dań.",
    mainIngredients: "Główne składniki",
    navigationLabel: "Nawigacja po obiadach",
    back: "Wstecz",
    next: "Następny pomysł",
    recipeSearch: "Szukaj przepisu w Google",
    recipeSearchTerm: "przepis",
    noIdeasLoaded: "Nie wczytano pomysłów",
    noDinnerIdeasYet: "Nie ma jeszcze pomysłów na obiad",
    noIdeasDescription: "Dodaj dania do shared/data/dinners.json, aby zacząć losowanie.",
    dataUnavailable: "Brak danych",
    loadErrorName: "Nie udało się wczytać pomysłów na obiad",
    loadErrorDescription: "Uruchom te pliki z dowolnego statycznego serwera, aby przeglądarka mogła odczytać dane obiadów.",
    fallbackDescription: "Pomysł na rodzinny obiad.",
    ideaCount(count) {
      const mod10 = count % 10;
      const mod100 = count % 100;

      if (count === 1) {
        return `${count} pomysł`;
      }

      if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
        return `${count} pomysły`;
      }

      return `${count} pomysłów`;
    },
  },
};

const state = {
  dinners: [],
  currentDinnerId: null,
  previousDinnerIds: [],
  upcomingDinnerIds: [],
  recentDinnerIds: [],
  language: detectInitialLanguage(),
  loadStatus: "loading",
  loadError: null,
  isLanguageMenuOpen: false,
};

const elements = {
  appTitle: document.querySelector("#appTitle"),
  poolCount: document.querySelector("#poolCount"),
  languageSwitcher: document.querySelector("#languageSwitcher"),
  languageToggle: document.querySelector("#languageToggle"),
  languageToggleFlag: document.querySelector("#languageToggleFlag"),
  languageMenu: document.querySelector("#languageMenu"),
  languageButtons: document.querySelectorAll("[data-language]"),
  dinnerImage: document.querySelector("#dinnerImage"),
  dinnerName: document.querySelector("#dinnerName"),
  dinnerDescription: document.querySelector("#dinnerDescription"),
  ingredientHeading: document.querySelector("#ingredientHeading"),
  ingredientList: document.querySelector("#ingredientList"),
  dinnerNotes: document.querySelector("#dinnerNotes"),
  dinnerNavigation: document.querySelector("#dinnerNavigation"),
  backDinner: document.querySelector("#backDinner"),
  pickDinner: document.querySelector("#pickDinner"),
  pickLabel: document.querySelector("#pickLabel"),
  recipeSearch: document.querySelector("#recipeSearch"),
};

function getCopy() {
  return UI_TEXT[state.language] || UI_TEXT.en;
}

function detectInitialLanguage() {
  const savedLanguage = readSavedLanguage();

  if (savedLanguage) {
    return savedLanguage;
  }

  const browserLanguages = Array.isArray(navigator.languages) && navigator.languages.length > 0
    ? navigator.languages
    : [navigator.language].filter(Boolean);

  for (const language of browserLanguages) {
    const normalizedLanguage = language.toLowerCase();

    if (normalizedLanguage.startsWith("sv")) {
      return "sv";
    }

    if (
      normalizedLanguage.startsWith("no") ||
      normalizedLanguage.startsWith("nb") ||
      normalizedLanguage.startsWith("nn")
    ) {
      return "no";
    }

    if (normalizedLanguage.startsWith("pl")) {
      return "pl";
    }
  }

  return "en";
}

function readSavedLanguage() {
  try {
    const savedLanguage = localStorage.getItem(LANGUAGE_STORAGE_KEY);
    return Object.prototype.hasOwnProperty.call(UI_TEXT, savedLanguage) ? savedLanguage : null;
  } catch (error) {
    return null;
  }
}

function saveLanguage(language) {
  try {
    localStorage.setItem(LANGUAGE_STORAGE_KEY, language);
  } catch (error) {
    // The selected language still applies for this page view if storage is unavailable.
  }
}

async function loadDinners() {
  const response = await fetch(DATA_URL, { cache: "no-store" });

  if (!response.ok) {
    throw new Error(`Could not load ${DATA_URL}`);
  }

  const dinners = await response.json();
  return dinners.map(normalizeDinner).filter(Boolean);
}

function normalizeDinner(dinner) {
  if (!dinner || !dinner.id || !dinner.name) {
    return null;
  }

  return {
    id: dinner.id,
    name: dinner.name,
    description: dinner.description || UI_TEXT.en.fallbackDescription,
    mainIngredients: Array.isArray(dinner.mainIngredients) ? dinner.mainIngredients : [],
    image: dinner.image || null,
    notes: dinner.notes || "",
    translations: dinner.translations || {},
  };
}

function resolveAssetPath(path) {
  if (!path) {
    return FALLBACK_IMAGE;
  }

  if (/^(?:[a-z]+:)?\/\//i.test(path) || path.startsWith("/") || path.startsWith("data:") || path.startsWith("blob:")) {
    return path;
  }

  return `${SHARED_ASSET_PREFIX}${path}`;
}

function shuffleItems(items) {
  const shuffledItems = [...items];

  for (let i = shuffledItems.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffledItems[i], shuffledItems[j]] = [shuffledItems[j], shuffledItems[i]];
  }

  return shuffledItems;
}

function createShuffledDinnerQueue() {
  const recentDinnerIds = new Set(state.recentDinnerIds.slice(-RECENT_REPEAT_BUFFER_SIZE));
  const shuffledDinnerIds = shuffleItems(state.dinners.map((dinner) => dinner.id));

  if (recentDinnerIds.size === 0) {
    return shuffledDinnerIds;
  }

  const delayedDinnerIds = [];
  const availableDinnerIds = [];

  shuffledDinnerIds.forEach((dinnerId) => {
    if (recentDinnerIds.has(dinnerId)) {
      delayedDinnerIds.push(dinnerId);
      return;
    }

    availableDinnerIds.push(dinnerId);
  });

  return [...availableDinnerIds, ...delayedDinnerIds];
}

function getDinnerById(dinnerId) {
  return state.dinners.find((dinner) => dinner.id === dinnerId) || null;
}

function rememberRecentDinner(dinnerId) {
  state.recentDinnerIds.push(dinnerId);

  if (state.recentDinnerIds.length > RECENT_REPEAT_BUFFER_SIZE) {
    state.recentDinnerIds = state.recentDinnerIds.slice(-RECENT_REPEAT_BUFFER_SIZE);
  }
}

function pickRandomDinner() {
  if (state.dinners.length === 0) {
    state.currentDinnerId = null;
    renderDinner(null);
    return;
  }

  if (state.upcomingDinnerIds.length === 0) {
    state.upcomingDinnerIds = createShuffledDinnerQueue();
  }

  const nextDinnerId = state.upcomingDinnerIds.shift();
  const nextDinner = getDinnerById(nextDinnerId);

  if (!nextDinner) {
    pickRandomDinner();
    return;
  }

  if (state.currentDinnerId) {
    state.previousDinnerIds.push(state.currentDinnerId);
  }

  state.currentDinnerId = nextDinner.id;
  rememberRecentDinner(nextDinner.id);
  renderDinner(nextDinner);
}

function showPreviousDinner() {
  const previousDinnerId = state.previousDinnerIds.pop();

  if (!previousDinnerId) {
    updateBackButton();
    return;
  }

  const previousDinner = state.dinners.find((dinner) => dinner.id === previousDinnerId);

  if (!previousDinner) {
    updateBackButton();
    return;
  }

  state.currentDinnerId = previousDinner.id;
  renderDinner(previousDinner);
}

function getCurrentDinner() {
  return state.dinners.find((dinner) => dinner.id === state.currentDinnerId) || null;
}

function getLocalizedDinner(dinner) {
  if (!dinner) {
    return null;
  }

  const translation = dinner.translations?.[state.language] || {};

  return {
    ...dinner,
    name: translation.name || dinner.name,
    description: translation.description || dinner.description || getCopy().fallbackDescription,
    mainIngredients: Array.isArray(translation.mainIngredients) && translation.mainIngredients.length > 0
      ? translation.mainIngredients
      : dinner.mainIngredients,
    notes: translation.notes ?? dinner.notes,
  };
}

function getRecipeSearchQuery(dinner) {
  const localizedDinner = getLocalizedDinner(dinner);

  if (!localizedDinner) {
    return "";
  }

  return `${localizedDinner.name} ${getCopy().recipeSearchTerm}`;
}

function openRecipeSearch() {
  const searchQuery = getRecipeSearchQuery(getCurrentDinner());

  if (!searchQuery) {
    return;
  }

  const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(searchQuery)}`;
  window.open(searchUrl, "_blank", "noopener,noreferrer");
}

function renderStaticText() {
  const copy = getCopy();
  const selectedLanguageName = copy.languages[state.language];
  document.documentElement.lang = state.language;
  document.title = copy.pageTitle;
  elements.appTitle.textContent = copy.appTitle;
  elements.languageSwitcher.setAttribute("aria-label", copy.languageLabel);
  elements.languageToggle.setAttribute("aria-label", `${copy.languageLabel}: ${selectedLanguageName}`);
  elements.languageToggle.setAttribute("aria-expanded", String(state.isLanguageMenuOpen));
  elements.languageToggle.title = selectedLanguageName;
  elements.languageToggleFlag.textContent = LANGUAGE_FLAGS[state.language];
  elements.languageMenu.hidden = !state.isLanguageMenuOpen;
  elements.ingredientHeading.textContent = copy.mainIngredients;
  elements.dinnerNavigation.setAttribute("aria-label", copy.navigationLabel);
  elements.backDinner.setAttribute("aria-label", copy.back);
  elements.backDinner.title = copy.back;
  elements.pickLabel.textContent = copy.next;
  elements.recipeSearch.setAttribute("aria-label", copy.recipeSearch);
  elements.recipeSearch.title = copy.recipeSearch;

  elements.languageButtons.forEach((button) => {
    const language = button.dataset.language;
    const isActive = language === state.language;
    button.setAttribute("aria-label", copy.languages[language]);
    button.setAttribute("aria-checked", String(isActive));
    button.title = copy.languages[language];

    const label = button.querySelector("span:last-child");
    if (label) {
      label.textContent = copy.languages[language];
    }
  });
}

function renderApp() {
  renderStaticText();

  if (state.loadStatus === "loading") {
    renderLoading();
    return;
  }

  if (state.loadStatus === "error") {
    renderLoadError();
    return;
  }

  renderDinner(getCurrentDinner());
}

function renderLoading() {
  const copy = getCopy();
  elements.poolCount.textContent = copy.loadingIdeas;
  elements.dinnerImage.src = FALLBACK_IMAGE;
  elements.dinnerImage.alt = "";
  elements.dinnerName.textContent = copy.loadingDinnerName;
  elements.dinnerDescription.textContent = copy.loadingDescription;
  elements.ingredientList.replaceChildren();
  elements.dinnerNotes.textContent = "";
  elements.recipeSearch.disabled = true;
  updateBackButton();
}

function renderLoadError() {
  const copy = getCopy();
  elements.poolCount.textContent = copy.dataUnavailable;
  elements.dinnerImage.src = FALLBACK_IMAGE;
  elements.dinnerImage.alt = "";
  elements.dinnerName.textContent = copy.loadErrorName;
  elements.dinnerDescription.textContent = copy.loadErrorDescription;
  elements.ingredientList.replaceChildren();
  elements.dinnerNotes.textContent = state.loadError?.message || "";
  elements.recipeSearch.disabled = true;
  updateBackButton();
}

function renderDinner(dinner) {
  const copy = getCopy();
  const localizedDinner = getLocalizedDinner(dinner);
  elements.ingredientList.replaceChildren();

  if (!localizedDinner) {
    elements.poolCount.textContent = copy.noIdeasLoaded;
    elements.dinnerImage.src = FALLBACK_IMAGE;
    elements.dinnerImage.alt = "";
    elements.dinnerName.textContent = copy.noDinnerIdeasYet;
    elements.dinnerDescription.textContent = copy.noIdeasDescription;
    elements.dinnerNotes.textContent = "";
    elements.recipeSearch.disabled = true;
    updateBackButton();
    return;
  }

  elements.poolCount.textContent = copy.ideaCount(state.dinners.length);
  elements.dinnerImage.src = resolveAssetPath(localizedDinner.image);
  elements.dinnerImage.alt = localizedDinner.image ? localizedDinner.name : "";
  elements.dinnerName.textContent = localizedDinner.name;
  elements.dinnerDescription.textContent = localizedDinner.description;
  elements.dinnerNotes.textContent = localizedDinner.notes;
  elements.recipeSearch.disabled = false;

  localizedDinner.mainIngredients.forEach((ingredient) => {
    const item = document.createElement("li");
    item.textContent = ingredient;
    elements.ingredientList.append(item);
  });

  updateBackButton();
}

function updateBackButton() {
  elements.backDinner.disabled = state.previousDinnerIds.length === 0;
}

function setLanguage(language) {
  if (!Object.prototype.hasOwnProperty.call(UI_TEXT, language)) {
    return;
  }

  state.language = language;
  state.isLanguageMenuOpen = false;
  saveLanguage(language);
  renderApp();
}

function setLanguageMenuOpen(isOpen) {
  if (state.isLanguageMenuOpen === isOpen) {
    return;
  }

  state.isLanguageMenuOpen = isOpen;
  renderStaticText();
}

async function init() {
  elements.pickDinner.addEventListener("click", pickRandomDinner);
  elements.backDinner.addEventListener("click", showPreviousDinner);
  elements.recipeSearch.addEventListener("click", openRecipeSearch);
  elements.languageToggle.addEventListener("click", () => setLanguageMenuOpen(!state.isLanguageMenuOpen));
  elements.languageButtons.forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.language));
  });
  document.addEventListener("click", (event) => {
    if (!state.isLanguageMenuOpen || elements.languageSwitcher.contains(event.target)) {
      return;
    }

    setLanguageMenuOpen(false);
  });
  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape" || !state.isLanguageMenuOpen) {
      return;
    }

    setLanguageMenuOpen(false);
    elements.languageToggle.focus();
  });

  renderApp();

  try {
    state.dinners = await loadDinners();
    state.loadStatus = "ready";
    pickRandomDinner();
  } catch (error) {
    state.loadStatus = "error";
    state.loadError = error;
    renderApp();
  }
}

init();
