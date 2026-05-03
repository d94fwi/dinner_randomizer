const DATA_URL = "data/dinners.json";
const FALLBACK_IMAGE = "assets/dinner-table.jpg";

const state = {
  dinners: [],
  currentDinnerId: null,
  previousDinnerIds: [],
};

const elements = {
  poolCount: document.querySelector("#poolCount"),
  dinnerImage: document.querySelector("#dinnerImage"),
  dinnerName: document.querySelector("#dinnerName"),
  dinnerDescription: document.querySelector("#dinnerDescription"),
  ingredientList: document.querySelector("#ingredientList"),
  dinnerNotes: document.querySelector("#dinnerNotes"),
  backDinner: document.querySelector("#backDinner"),
  pickDinner: document.querySelector("#pickDinner"),
};

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
    description: dinner.description || "A family dinner idea.",
    mainIngredients: Array.isArray(dinner.mainIngredients) ? dinner.mainIngredients : [],
    image: dinner.image || null,
    recipeUrl: dinner.recipeUrl || null,
    notes: dinner.notes || "",
  };
}

function pickRandomDinner() {
  if (state.dinners.length === 0) {
    state.currentDinnerId = null;
    renderDinner(null);
    return;
  }

  let nextDinner = state.dinners[Math.floor(Math.random() * state.dinners.length)];

  if (state.dinners.length > 1) {
    while (nextDinner.id === state.currentDinnerId) {
      nextDinner = state.dinners[Math.floor(Math.random() * state.dinners.length)];
    }
  }

  if (state.currentDinnerId) {
    state.previousDinnerIds.push(state.currentDinnerId);
  }

  state.currentDinnerId = nextDinner.id;
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

function renderDinner(dinner) {
  elements.ingredientList.replaceChildren();

  if (!dinner) {
    elements.poolCount.textContent = "No ideas loaded";
    elements.dinnerImage.src = FALLBACK_IMAGE;
    elements.dinnerImage.alt = "";
    elements.dinnerName.textContent = "No dinner ideas yet";
    elements.dinnerDescription.textContent = "Add dinners to data/dinners.json to start picking.";
    elements.dinnerNotes.textContent = "";
    updateBackButton();
    return;
  }

  elements.poolCount.textContent = `${state.dinners.length} idea${state.dinners.length === 1 ? "" : "s"}`;
  elements.dinnerImage.src = dinner.image || FALLBACK_IMAGE;
  elements.dinnerImage.alt = dinner.image ? dinner.name : "";
  elements.dinnerName.textContent = dinner.name;
  elements.dinnerDescription.textContent = dinner.description;
  elements.dinnerNotes.textContent = dinner.notes;

  dinner.mainIngredients.forEach((ingredient) => {
    const item = document.createElement("li");
    item.textContent = ingredient;
    elements.ingredientList.append(item);
  });

  updateBackButton();
}

function updateBackButton() {
  elements.backDinner.disabled = state.previousDinnerIds.length === 0;
}

async function init() {
  elements.pickDinner.addEventListener("click", pickRandomDinner);
  elements.backDinner.addEventListener("click", showPreviousDinner);

  try {
    state.dinners = await loadDinners();
    pickRandomDinner();
  } catch (error) {
    elements.poolCount.textContent = "Data unavailable";
    elements.dinnerName.textContent = "Could not load dinner ideas";
    elements.dinnerDescription.textContent =
      "Serve these files from any static host so the browser can read data/dinners.json.";
    elements.dinnerNotes.textContent = error.message;
  }
}

init();
